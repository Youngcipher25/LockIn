import SwiftUI
import Supabase

enum SyncMethod: String, CaseIterable, Identifiable {
    case account = "Account Sync"
    case quick = "Quick Transfer"
    var id: String { self.rawValue }
}

struct SyncView: View {
    @EnvironmentObject var taskStore: TaskStore
    @StateObject private var syncManager = SupabaseSyncManager.shared
    
    @State private var selectedMethod: SyncMethod = .account
    
    // Account States
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showDeleteConfirmation = false
    @State private var showDownloadConfirmation = false
    @State private var isPasswordVisible = false
    
    // Quick Transfer States
    @State private var transferCode = ""
    @State private var generatedCode: String?
    @State private var showQuickRestoreConfirmation = false
    @State private var restoredTasks: [TaskItem] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Method Selector
                Picker("Sync Method", selection: $selectedMethod) {
                    ForEach(SyncMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 4)
                
                if selectedMethod == .account {
                    accountSyncView
                } else {
                    quickTransferView
                }
            }
            .padding(20)
        }
        .background(Brand.systemGroupedBackground)
        .navigationTitle("Cloud Sync")
        .alert("Replace Local Data?", isPresented: $showDownloadConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Replace", role: .destructive) {
                Task {
                    do {
                        let tasks = try await syncManager.downloadTasks()
                        taskStore.tasks = tasks
                        HapticManager.notification(.success)
                    } catch {
                        HapticManager.notification(.error)
                    }
                }
            }
        } message: {
            Text("This will replace all your local tasks with data from your account.")
        }
        .alert("Restored Tasks Found", isPresented: $showQuickRestoreConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Import Tasks", role: .destructive) {
                // Merge tasks
                let currentIds = Set(taskStore.tasks.map { $0.id })
                let newTasks = restoredTasks.filter { !currentIds.contains($0.id) }
                taskStore.tasks.append(contentsOf: newTasks)
                HapticManager.notification(.success)
            }
        } message: {
            Text("We found \(restoredTasks.count) tasks from the transfer code. Would you like to import them into your local database?")
        }
        .alert("Delete Cloud Data?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete & Sign Out", role: .destructive) {
                Task {
                    do {
                        try await syncManager.deleteCloudData()
                        HapticManager.notification(.success)
                    } catch {
                        HapticManager.notification(.error)
                    }
                }
            }
        } message: {
            Text("This will permanently delete all your tasks from the cloud and sign you out.")
        }
    }
    
    // MARK: - Account Sync View
    private var accountSyncView: some View {
        VStack(spacing: 24) {
            if syncManager.isLoggedIn {
                loggedInAccountView
            } else {
                authFormView
            }
        }
    }
    
    private var loggedInAccountView: some View {
        VStack(spacing: 24) {
            LockInCard(backgroundColor: Color.green.opacity(0.05)) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Color.green.opacity(0.12)).frame(width: 50, height: 50)
                        Image(systemName: "person.crop.circle.fill").font(.title2).foregroundColor(.green)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Signed In").font(.headline).fontWeight(.bold)
                        Text(syncManager.userEmail ?? "").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                }
            }
            
            syncSection(title: "Account Actions", icon: "arrow.triangle.2.circlepath") {
                VStack(spacing: 16) {
                    Button {
                        Task { try? await syncManager.uploadTasks(taskStore.tasks) }
                    } label: {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up.fill").frame(width: 24)
                            Text("Upload to Cloud").fontWeight(.medium)
                            Spacer()
                            if syncManager.isSyncing { ProgressView() }
                        }
                    }
                    Divider()
                    Button { showDownloadConfirmation = true } label: {
                        HStack {
                            Image(systemName: "icloud.and.arrow.down.fill").frame(width: 24)
                            Text("Download from Cloud").fontWeight(.medium)
                            Spacer()
                        }
                    }
                }
            }
            
            syncSection(title: "Account", icon: "person.crop.circle") {
                VStack(spacing: 16) {
                    Button { Task { await syncManager.signOut() } } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right").frame(width: 24)
                            Text("Sign Out")
                            Spacer()
                        }.foregroundColor(.orange)
                    }
                    Divider()
                    Button(role: .destructive) { showDeleteConfirmation = true } label: {
                        HStack {
                            Image(systemName: "trash.fill").frame(width: 24)
                            Text("Delete Data & Sign Out")
                            Spacer()
                        }
                    }
                }
            }
        }
    }
    
    private var authFormView: some View {
        VStack(spacing: 24) {
            LockInCard(backgroundColor: Brand.primary.opacity(0.05)) {
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.key.fill").font(.system(size: 40)).foregroundColor(Brand.primary)
                    Text("Secure Account Sync").font(.headline)
                    Text("Keep your tasks synced across all your devices permanently using a private account.").font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity)
            }
            
            LockInCard {
                VStack(spacing: 16) {
                    TextField("Email", text: $email).keyboardType(.emailAddress).autocapitalization(.none).padding().background(Color.primary.opacity(0.03)).clipShape(RoundedRectangle(cornerRadius: 12))
                    SecureField("Password", text: $password).padding().background(Color.primary.opacity(0.03)).clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    if let error = syncManager.errorMessage { Text(error).font(.caption).foregroundColor(.red) }
                    
                    Button {
                        Task {
                            if isSignUp { try? await syncManager.signUp(email: email, password: password) }
                            else { try? await syncManager.signIn(email: email, password: password) }
                        }
                    } label: {
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .fontWeight(.bold).frame(maxWidth: .infinity).padding().background(Brand.primary).foregroundColor(.white).cornerRadius(12)
                    }
                    
                    Button { withAnimation { isSignUp.toggle() } } label: {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up").font(.footnote)
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Transfer View
    private var quickTransferView: some View {
        VStack(spacing: 24) {
            // Hero
            LockInCard(backgroundColor: Color.orange.opacity(0.05)) {
                VStack(spacing: 16) {
                    Image(systemName: "bolt.horizontal.circle.fill").font(.system(size: 40)).foregroundColor(.orange)
                    Text("One-Time Transfer").font(.headline)
                    Text("Move data to another device using a 6-digit code. No account required. Code expires in 15 minutes.").font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity)
            }
            
            // Generate Section
            syncSection(title: "Send Data", icon: "paperplane.fill") {
                VStack(spacing: 16) {
                    if let code = syncManager.activeTransferCode {
                        VStack(spacing: 12) {
                            Text("Your Transfer Code").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                            Text(code).font(.system(size: 48, weight: .black, design: .monospaced)).foregroundColor(.orange).tracking(8)
                            Text("Enter this code on your other device.").font(.footnote).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    } else {
                        Button {
                            Task { try? await syncManager.generateTransferCode(tasks: taskStore.tasks) }
                        } label: {
                            HStack {
                                if syncManager.transferLoading { ProgressView().padding(.trailing, 8) }
                                Text(syncManager.transferLoading ? "Generating..." : "Generate Transfer Code").fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity).padding().background(Color.orange).foregroundColor(.white).cornerRadius(12)
                        }
                        .disabled(syncManager.transferLoading)
                    }
                }
            }
            
            // Receive Section
            syncSection(title: "Receive Data", icon: "square.and.arrow.down.fill") {
                VStack(spacing: 16) {
                    TextField("Enter 6-digit code", text: $transferCode)
                        .font(.system(.title3, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color.primary.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Button {
                        Task {
                            do {
                                restoredTasks = try await syncManager.restoreFromCode(transferCode)
                                showQuickRestoreConfirmation = true
                            } catch {
                                HapticManager.notification(.error)
                            }
                        }
                    } label: {
                        Text("Restore Data").fontWeight(.bold).frame(maxWidth: .infinity).padding().background(transferCode.count == 6 ? Brand.primary : Color.gray.opacity(0.3)).foregroundColor(.white).cornerRadius(12)
                    }
                    .disabled(transferCode.count != 6 || syncManager.transferLoading)
                }
            }
            
            if let error = syncManager.errorMessage {
                Text(error).font(.caption).foregroundColor(.red).padding(.horizontal)
            }
        }
    }
    
    private func syncSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.caption).fontWeight(.bold)
                Text(title).font(.caption).fontWeight(.bold).textCase(.uppercase)
            }
            .foregroundStyle(.secondary).padding(.leading, 4)
            LockInCard { content() }
        }
    }
}
