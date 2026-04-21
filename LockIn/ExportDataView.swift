import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ExportDataView: View {
    @EnvironmentObject var taskStore: TaskStore
    @State private var exportItem: SharedItem?
    @State private var showingShareSheet = false
    @State private var isImporting = false
    @State private var importError: String?
    @State private var showImportSuccess = false
    @State private var importedCount = 0

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Info
                    VStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Brand.primary.opacity(0.2))
                            .symbolRenderingMode(.hierarchical)
                        
                        Text("Data Management")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Securely export or restore your tasks. Your data is yours to keep.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 20)
                    
                    // Export Formats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export Backup")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.leading, 8)
                        
                        LockInCard {
                            VStack(spacing: 0) {
                                actionButton(title: "Export JSON", description: "Best for full backups and restoration", icon: "doc.text.fill", color: Brand.primary) {
                                    exportToJSON()
                                }
                                
                                Divider().padding(.vertical, 8)
                                
                                actionButton(title: "Export CSV", description: "Best for Excel and spreadsheets", icon: "tablecells.fill", color: .green) {
                                    exportToCSV()
                                }
                            }
                        }
                    }
                    
                    // Import Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Restore Data")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.leading, 8)
                        
                        LockInCard {
                            VStack(alignment: .leading, spacing: 16) {
                                actionButton(title: "Import JSON Backup", description: "Restore your tasks from a previous backup", icon: "arrow.down.doc.fill", color: .orange) {
                                    isImporting = true
                                }
                                
                                if let error = importError {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                        Text(error)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                    
                    // Stats
                    LockInCard(backgroundColor: Brand.primary.opacity(0.05)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Local Database")
                                    .font(.headline)
                                Text("\(taskStore.tasks.count) total tasks stored locally")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "internaldrive.fill")
                                .foregroundColor(Brand.primary)
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Backup & Restore")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $exportItem) { item in
            ShareSheet(activityItems: [item.data])
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result: result)
        }
        .alert("Import Successful", isPresented: $showImportSuccess) {
            Button("OK") { }
        } message: {
            Text("Successfully imported \(importedCount) tasks into your database.")
        }
    }

    private func actionButton(title: String, description: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.impact(.medium)
            action()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Export Logic
    
    private func exportToJSON() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(taskStore.tasks) {
            let filename = "LockIn_Backup_\(Date().formatted(date: .numeric, time: .omitted)).json"
            guard let url = saveToTempFile(data: data, filename: filename) else { return }
            exportItem = SharedItem(data: url)
        }
    }
    
    private func exportToCSV() {
        var csvString = "Title,Date,Priority,Notes,Completed,Private,CreatedAt\n"
        let dateFormatter = ISO8601DateFormatter()
        
        for task in taskStore.tasks {
            let completed = task.completed ? "Yes" : "No"
            let isPrivate = task.isPrivate ? "Yes" : "No"
            let dateStr = dateFormatter.string(from: task.date)
            let createdStr = dateFormatter.string(from: task.createdAt)
            let notes = (task.notes ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let title = task.title.replacingOccurrences(of: "\"", with: "\"\"")
            
            let row = "\"\(title)\",\"\(dateStr)\",\(task.priority.rawValue),\"\(notes)\",\(completed),\(isPrivate),\"\(createdStr)\"\n"
            csvString += row
        }
        
        if let data = csvString.data(using: .utf8) {
            let filename = "LockIn_Tasks_\(Date().formatted(date: .numeric, time: .omitted)).csv"
            guard let url = saveToTempFile(data: data, filename: filename) else { return }
            exportItem = SharedItem(data: url)
        }
    }
    
    private func saveToTempFile(data: Data, filename: String) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: url)
        return url
    }
    
    // MARK: - Import Logic
    
    private func handleImport(result: Result<[URL], Error>) {
        do {
            let selectedFiles = try result.get()
            guard let fileURL = selectedFiles.first else { return }
            
            // Security requirement for files outside our sandbox
            if fileURL.startAccessingSecurityScopedResource() {
                defer { fileURL.stopAccessingSecurityScopedResource() }
                
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let importedTasks = try decoder.decode([TaskItem].self, from: data)
                
                // Merge tasks (don't duplicate by ID)
                let currentIds = Set(taskStore.tasks.map { $0.id })
                let newTasks = importedTasks.filter { !currentIds.contains($0.id) }
                
                if !newTasks.isEmpty {
                    taskStore.tasks.append(contentsOf: newTasks)
                    importedCount = newTasks.count
                    showImportSuccess = true
                    HapticManager.notification(.success)
                    importError = nil
                } else {
                    importError = "No new tasks found in backup file."
                }
            }
        } catch {
            importError = "Failed to import: \(error.localizedDescription)"
            HapticManager.notification(.error)
        }
    }
}

// Helper types for sharing
struct SharedItem: Identifiable {
    let id = UUID()
    let data: Any
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview("Export") {
    NavigationStack {
        ExportDataView()
            .environmentObject(TaskStore())
    }
}
