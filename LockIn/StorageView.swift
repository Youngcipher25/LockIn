import SwiftUI

struct StorageView: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Status Overview
                    LockInCard {
                        VStack(spacing: 20) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "shield.checkered")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Local Storage Active")
                                        .font(.headline)
                                    Text("All data is stored on this iPhone")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            
                            Divider()
                            
                            HStack {
                                storageMetric(value: "42 KB", label: "App Data")
                                Spacer()
                                storageMetric(value: "1.2 MB", label: "Media")
                                Spacer()
                                storageMetric(value: "None", label: "Cloud Sync")
                            }
                        }
                    }
                    
                    // Detailed Sections
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Security Configuration")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.leading, 8)
                        
                        LockInCard {
                            VStack(spacing: 16) {
                                storageRow(title: "AES-256 Encryption", description: "Standard military-grade encryption for all tasks.", icon: "lock.shield.fill", color: Brand.primary)
                                
                                Divider()
                                
                                storageRow(title: "Biometric Protection", description: "FaceID required for access to secure storage.", icon: "faceid", color: Brand.secondary)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Backup & Sync")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .padding(.leading, 8)
                        
                        LockInCard {
                            VStack(alignment: .leading, spacing: 16) {
                                storageRow(title: "iCloud Syncing", description: "Disabled. Turn on in Cloud Settings to sync across devices.", icon: "cloud.fill", color: .blue)
                                
                                Divider()
                                
                                storageRow(title: "Auto-Backup", description: "Disabled. Back up manually using the Export page.", icon: "arrow.clockwise.icloud.fill", color: .orange)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Storage")
    }
    
    private func storageMetric(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func storageRow(title: String, description: String, icon: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview("Storage") {
    NavigationStack {
        StorageView()
    }
}
