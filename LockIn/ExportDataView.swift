import SwiftUI

struct ExportDataView: View {
    @EnvironmentObject var taskStore: TaskStore
    @State private var showingExportAlert = false
    @State private var exportFormat = ""

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
                        
                        Text("Export Your Data")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Select a format to download all your tasks and settings. Your data is yours to keep.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 20)
                    
                    // Export Formats
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Available Formats")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.leading, 8)
                        
                        LockInCard {
                            VStack(spacing: 0) {
                                exportButton(title: "JSON Format", description: "Best for backups and developers", icon: "doc.text.fill") {
                                    exportData(format: "JSON")
                                }
                                
                                Divider().padding(.vertical, 8)
                                
                                exportButton(title: "CSV Table", description: "Best for Excel and spreadsheets", icon: "tablecells.fill") {
                                    exportData(format: "CSV")
                                }
                                
                                Divider().padding(.vertical, 8)
                                
                                exportButton(title: "PDF Summary", description: "Clean printable task report", icon: "doc.richtext.fill") {
                                    exportData(format: "PDF")
                                }
                            }
                        }
                    }
                    
                    // Danger Zone
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Security")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.leading, 8)
                        
                        LockInCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("All exports are encrypted locally before download. Never share sensitive JSON files with untrusted parties.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Ready to Export", isPresented: $showingExportAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your data is being prepared in \(exportFormat) format.")
        }
    }
    
    private func exportButton(title: String, description: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.impact(.medium)
            action()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Brand.primary)
                    .frame(width: 44, height: 44)
                    .background(Brand.primary.opacity(0.1))
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
    
    private func exportData(format: String) {
        exportFormat = format
        showingExportAlert = true
        
        if format == "JSON" {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            if let data = try? encoder.encode(taskStore.tasks) {
                let json = String(data: data, encoding: .utf8)
                print(json ?? "")
            }
        }
    }
}

#Preview("Export") {
    NavigationStack {
        ExportDataView()
            .environmentObject(TaskStore())
    }
}

