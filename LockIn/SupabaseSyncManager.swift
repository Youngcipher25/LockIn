import Foundation
import SwiftUI
import Supabase

// MARK: - Supabase Task Model (matches the "tasks" table)
struct SupabaseTask: Codable {
    let id: String
    let user_id: String?
    let title: String
    let date: String // ISO8601
    let priority: Int // Changed to Int to match Android (0, 1, 2)
    let notes: String?
    let isCompleted: Bool // Changed to match Android
    let created_at: String // ISO8601
    let isPrivate: Bool // Changed to match Android
}

// MARK: - Supabase Sync Manager
@MainActor
final class SupabaseSyncManager: ObservableObject {
    static let shared = SupabaseSyncManager()
    
    // Lazy initialization of the Supabase client
    private let client = SupabaseClient(
        supabaseURL: URL(string: "https://qhdqehchosusllwazgyo.supabase.co")!,
        supabaseKey: "sb_publishable_RmynHhXc0vLJgcEQOlFTLw_I-4bFJa3",
        options: SupabaseClientOptions(
            auth: .init(emitLocalSessionAsInitialSession: true)
        )
    )
    
    @Published var isLoggedIn = false
    @Published var userEmail: String?
    @Published var isSyncing = false
    @Published var syncStatus: String = ""
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?
    
    private let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    
    private init() {
        Task {
            checkSession()
        }
    }
    
    // MARK: - Session Management
    
    func checkSession() {
        if let session = client.auth.currentSession {
            isLoggedIn = true
            userEmail = session.user.email
        } else {
            isLoggedIn = true // Set to false if not signed in, but currentSession might be nil if not loaded yet
            // Wait, let's use session which is usually more reliable
            if let session = client.auth.currentSession {
                 isLoggedIn = true
                 userEmail = session.user.email
            } else {
                 isLoggedIn = false
                 userEmail = nil
            }
        }
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String) async throws {
        errorMessage = nil
        do {
            try await client.auth.signUp(email: email, password: password)
            syncStatus = "Account created! Check your email to confirm."
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        errorMessage = nil
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            isLoggedIn = true
            userEmail = session.user.email
            syncStatus = "Signed in successfully."
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
            print("Sign out error: \(error)")
        }
        isLoggedIn = false
        userEmail = nil
        syncStatus = ""
    }
    
    // MARK: - Upload Tasks to Supabase
    
    func uploadTasks(_ tasks: [TaskItem]) async throws {
        guard isLoggedIn else {
            errorMessage = "Not signed in."
            return
        }
        
        isSyncing = true
        syncStatus = "Uploading tasks..."
        errorMessage = nil
        
        do {
            guard let session = client.auth.currentSession else {
                errorMessage = "Session expired."
                return
            }
            let userId = session.user.id.uuidString
            
            // Delete existing tasks for this user first (full replace sync)
            try await client.from("tasks")
                .delete()
                .eq("user_id", value: userId)
                .execute()
            
            // Upload all current tasks
            if !tasks.isEmpty {
                let supabaseTasks = tasks.map { task in
                    // Map priority to integer: low=0, medium=1, high=2
                    let priorityInt: Int
                    switch task.priority {
                    case .low: priorityInt = 0
                    case .medium: priorityInt = 1
                    case .high: priorityInt = 2
                    }
                    
                    return SupabaseTask(
                        id: task.id.uuidString,
                        user_id: userId,
                        title: task.title,
                        date: iso8601.string(from: task.date),
                        priority: priorityInt,
                        notes: task.notes,
                        isCompleted: task.completed,
                        created_at: iso8601.string(from: task.createdAt),
                        isPrivate: task.isPrivate
                    )
                }
                
                try await client.from("tasks")
                    .insert(supabaseTasks)
                    .execute()
            }
            
            lastSyncDate = Date()
            syncStatus = "Upload complete! \(tasks.count) task(s) synced."
            isSyncing = false
        } catch {
            isSyncing = false
            errorMessage = "Upload failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Download Tasks from Supabase
    
    func downloadTasks() async throws -> [TaskItem] {
        guard isLoggedIn else {
            errorMessage = "Not signed in."
            return []
        }
        
        isSyncing = true
        syncStatus = "Downloading tasks..."
        errorMessage = nil
        
        do {
            guard let session = client.auth.currentSession else {
                errorMessage = "Session expired."
                return []
            }
            let userId = session.user.id.uuidString
            
            let response: [SupabaseTask] = try await client.from("tasks")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            let tasks = response.compactMap { st -> TaskItem? in
                guard let date = iso8601.date(from: st.date) else { return nil }
                let createdAt = iso8601.date(from: st.created_at) ?? Date()
                
                // Map integer back to priority enum: 0=low, 1=medium, 2=high
                let priority: Priority
                switch st.priority {
                case 0: priority = .low
                case 2: priority = .high
                default: priority = .medium
                }
                
                return TaskItem(
                    id: UUID(uuidString: st.id) ?? UUID(),
                    title: st.title,
                    date: date,
                    priority: priority,
                    notes: st.notes,
                    completed: st.isCompleted,
                    createdAt: createdAt,
                    isPrivate: st.isPrivate
                )
            }
            
            lastSyncDate = Date()
            syncStatus = "Downloaded \(tasks.count) task(s)."
            isSyncing = false
            return tasks
        } catch {
            isSyncing = false
            errorMessage = "Download failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Delete Account & Data
    
    func deleteCloudData() async throws {
        guard isLoggedIn else { return }
        
        isSyncing = true
        syncStatus = "Deleting cloud data..."
        errorMessage = nil
        
        do {
            guard let session = client.auth.currentSession else { return }
            let userId = session.user.id.uuidString
            
            // Delete all tasks
            try await client.from("tasks")
                .delete()
                .eq("user_id", value: userId)
                .execute()
            
            // Sign out
            await signOut()
            
            syncStatus = "Cloud data deleted. Your local data is preserved."
            isSyncing = false
        } catch {
            isSyncing = false
            errorMessage = "Delete failed: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Quick Transfer (One-time Code)
    
    @Published var activeTransferCode: String?
    @Published var transferLoading = false
    
    func generateTransferCode(tasks: [TaskItem]) async throws -> String {
        transferLoading = true
        errorMessage = nil
        
        do {
            let code = String(format: "%06d", Int.random(in: 0...999999))
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(tasks)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            
            // Set expiration to 15 minutes from now
            let expiresAt = iso8601.string(from: Date().addingTimeInterval(15 * 60))
            
            let payload: [String: String] = [
                "sync_code": code,
                "payload": jsonString,
                "expires_at": expiresAt
            ]
            
            try await client.from("sync_sessions")
                .insert(payload)
                .execute()
            
            activeTransferCode = code
            transferLoading = false
            return code
        } catch {
            transferLoading = false
            errorMessage = "Failed to generate code: \(error.localizedDescription)"
            throw error
        }
    }
    
    func restoreFromCode(_ code: String) async throws -> [TaskItem] {
        transferLoading = true
        errorMessage = nil
        
        do {
            // 1. Fetch the data
            let result: [[String: String]] = try await client.from("sync_sessions")
                .select()
                .eq("sync_code", value: code)
                .execute()
                .value
            
            guard let record = result.first, let jsonString = record["payload"] else {
                transferLoading = false
                errorMessage = "Invalid or expired code."
                throw NSError(domain: "Sync", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invalid or expired code."])
            }
            
            // 2. Decode the data
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            guard let jsonData = jsonString.data(using: .utf8) else {
                throw NSError(domain: "Sync", code: 500, userInfo: [NSLocalizedDescriptionKey: "Data corruption error."])
            }
            
            let tasks = try decoder.decode([TaskItem].self, from: jsonData)
            
            // 3. Delete the record (One-time use)
            try await client.from("sync_sessions")
                .delete()
                .eq("sync_code", value: code)
                .execute()
            
            transferLoading = false
            syncStatus = "Restored \(tasks.count) tasks!"
            return tasks
        } catch {
            transferLoading = false
            errorMessage = "Restore failed: \(error.localizedDescription)"
            throw error
        }
    }
}
