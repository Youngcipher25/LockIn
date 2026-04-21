import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var taskStore: TaskStore
    @AppStorage("notificationsEnabled") private var notifications = true
    @AppStorage("analyticsEnabled") private var analytics = false
    @AppStorage("darkMode") private var isDarkMode = false
    @AppStorage("isAuthenticated") private var isAuthenticated = false

    var body: some View {
        List {
            // MARK: - Profile Section
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Brand.primary.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundColor(Brand.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LockIn User")
                            .font(.headline)
                        Text("Privacy Enthusiast")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // MARK: - Preferences
            Section("Appearance") {
                Toggle(isOn: $isDarkMode) {
                    Label("Dark Mode", systemImage: "moon.fill")
                }
                .tint(Brand.primary)
                
                Toggle(isOn: $notifications) {
                    Label("Push Notifications", systemImage: "bell.fill")
                }
                .tint(Brand.primary)
            }
            
            // MARK: - Backend & Storage
            Section("Backend & System") {
                HStack {
                    Label("Active Tasks", systemImage: "checklist")
                    Spacer()
                    Text("\(taskStore.tasks.count)")
                        .fontWeight(.bold)
                        .foregroundColor(Brand.primary)
                }
                
                HStack {
                    Label("Storage Type", systemImage: "internaldrive.fill")
                    Spacer()
                    Text("AES-256 Encrypted")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                NavigationLink {
                    StorageView()
                } label: {
                    Label("Detailed Storage Info", systemImage: "folder.fill")
                }
            }
            
            // MARK: - Safety
            Section("Security") {
                Toggle(isOn: $analytics) {
                    Label("Help Improve LockIn", systemImage: "chart.bar.fill")
                }
                .tint(Brand.primary)
                
                Button(role: .destructive) {
                    withAnimation {
                        isAuthenticated = false
                    }
                } label: {
                    Label("Logout & Secure Session", systemImage: "lock.rectangle.on.rectangle")
                }
            }
            
            // MARK: - Data Management
            Section("Data Management") {
                NavigationLink {
                    ExportDataView()
                } label: {
                    Label("Export Local Database", systemImage: "square.and.arrow.up")
                }
                
                NavigationLink {
                    SyncView()
                } label: {
                    Label("Cloud Sync", systemImage: "icloud.and.arrow.up")
                }
            }
            
            // MARK: - About
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("2.1.0 (Production)")
                        .foregroundColor(.secondary)
                }
            } footer: {
                Text("LockIn uses AES-256 encrypted JSON file storage with .completeFileProtection. Your data never leaves this iPhone.")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview("Full App") {
    MainTabView()
        .environmentObject(TaskStore())
        .environmentObject(BiometricAuthManager.shared)
}

