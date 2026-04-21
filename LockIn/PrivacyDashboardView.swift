import SwiftUI

struct PrivacyDashboardView: View {
    
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var bioAuth: BiometricAuthManager
    
    @AppStorage("isPrivacyModeEnabled") private var isPrivacyModeEnabled = false
    @AppStorage("defaultPrivateTasks") private var defaultPrivateTasks = false
    @AppStorage("hidePrivateTaskTitles") private var hidePrivateTaskTitles = true
    
    @State private var showDeleteConfirmation = false
    
    // MARK: - Computed Stats
    private var totalTasks: Int { taskStore.tasks.count }
    private var privateTasks: Int { taskStore.tasks.filter { $0.isPrivate }.count }
    private var publicTasks: Int { totalTasks - privateTasks }
    private var privacyPercentage: Int {
        guard totalTasks > 0 else { return 0 }
        return Int((Double(privateTasks) / Double(totalTasks)) * 100)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Privacy Shield Hero
                privacyHero
                
                // MARK: - Privacy Stats
                privacyStats
                
                // MARK: - Biometric Protection
                privacySection(title: "Biometric Protection", icon: bioAuth.biometricIcon) {
                    VStack(spacing: 16) {
                        Toggle(isOn: $bioAuth.requireBiometricForPrivate) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Require \(bioAuth.biometricLabel) for Private Tasks")
                                    .fontWeight(.medium)
                                Text("Private tasks will be blurred until you authenticate")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tint(Brand.primary)
                        
                        if bioAuth.requireBiometricForPrivate {
                            Divider()
                            
                            // Auto-lock timer
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Auto-Lock Timer")
                                    .fontWeight(.medium)
                                
                                Picker("Auto-Lock", selection: $bioAuth.autoLockTimeout) {
                                    Text("Immediate").tag(0)
                                    Text("1 minute").tag(1)
                                    Text("5 minutes").tag(5)
                                    Text("15 minutes").tag(15)
                                    Text("30 minutes").tag(30)
                                }
                                .pickerStyle(.segmented)
                                
                                Text("Private tasks will re-lock after this duration of inactivity.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            // Quick lock/unlock
                            Button {
                                if bioAuth.isPrivateContentRevealed {
                                    bioAuth.lockPrivateContent()
                                } else {
                                    bioAuth.authenticate { _ in }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: bioAuth.isPrivateContentRevealed ? "lock.open.fill" : "lock.fill")
                                    Text(bioAuth.isPrivateContentRevealed ? "Lock Private Tasks Now" : "Unlock Private Tasks")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(bioAuth.isPrivateContentRevealed ? Color.red.opacity(0.1) : Brand.primary.opacity(0.1))
                                .foregroundColor(bioAuth.isPrivateContentRevealed ? .red : Brand.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                }
                
                // MARK: - Privacy Mode
                privacySection(title: "Privacy Mode", icon: "eye.slash.fill") {
                    VStack(spacing: 16) {
                        Toggle(isOn: .init(get: {
                            isPrivacyModeEnabled
                        }, set: { newValue in
                            withAnimation(.spring()) {
                                isPrivacyModeEnabled = newValue
                                NotificationManager.shared.updateAllNotifications(tasks: taskStore.tasks)
                            }
                        })) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Enable Privacy Mode")
                                    .fontWeight(.medium)
                                Text("Blur task titles and details across the app")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tint(Brand.primary)
                    }
                }
                
                // MARK: - Notification Privacy
                privacySection(title: "Notification Privacy", icon: "bell.badge.shield.fill") {
                    VStack(spacing: 16) {
                        Toggle(isOn: .init(get: {
                            UserDefaults.standard.bool(forKey: "hideNotificationDetails")
                        }, set: {
                            UserDefaults.standard.set($0, forKey: "hideNotificationDetails")
                            NotificationManager.shared.updateAllNotifications(tasks: taskStore.tasks)
                        })) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Conceal Private Details")
                                    .fontWeight(.medium)
                                Text("Show generic text in Lock Screen notifications")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .tint(Brand.primary)
                        
                        Divider()
                        
                        Button {
                            NotificationManager.shared.requestAuthorization()
                        } label: {
                            HStack {
                                Label("Notification Permissions", systemImage: "bell.fill")
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                        }
                        .foregroundColor(Brand.primary)
                    }
                }
                
                // MARK: - Task Defaults
                privacySection(title: "Task Defaults", icon: "lock.doc.fill") {
                    Toggle(isOn: $defaultPrivateTasks) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Default New Tasks to Private")
                                .fontWeight(.medium)
                            Text("All new tasks will be marked as private automatically")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .tint(Brand.privacy)
                }
                
                // MARK: - Data Control
                privacySection(title: "Data Control", icon: "square.stack.3d.up.fill") {
                    VStack(spacing: 16) {
                        // Make all tasks private
                        Button {
                            HapticManager.impact(.medium)
                            for i in taskStore.tasks.indices {
                                taskStore.tasks[i].isPrivate = true
                            }
                        } label: {
                            settingsRow(title: "Make All Tasks Private", icon: "lock.fill", color: Brand.privacy)
                        }
                        
                        Divider()
                        
                        // Make all tasks public
                        Button {
                            HapticManager.impact(.medium)
                            for i in taskStore.tasks.indices {
                                taskStore.tasks[i].isPrivate = false
                            }
                        } label: {
                            settingsRow(title: "Make All Tasks Public", icon: "lock.open.fill", color: Brand.primary)
                        }
                        
                        Divider()
                        
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            settingsRow(title: "Wipe All Data", icon: "trash", color: .red)
                        }
                    }
                }
                
                // MARK: - iOS Tip
                LockInCard(backgroundColor: Color.blue.opacity(0.05)) {
                    HStack(spacing: 12) {
                        Image(systemName: "iphone")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("iOS App Lock")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Text("You can also lock the entire LockIn app from iOS Settings > Face ID & Passcode > App Lock.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Text("LockIn uses local-only AES-256 encryption. Your data never leaves this device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
            }
            .padding(20)
        }
        .background(Brand.systemGroupedBackground)
        .navigationTitle("Privacy")
        .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                withAnimation {
                    taskStore.clearAll()
                }
                HapticManager.notification(.success)
            }
        } message: {
            Text("This will permanently delete all your tasks and cannot be undone.")
        }
    }
    
    // MARK: - Privacy Shield Hero
    private var privacyHero: some View {
        LockInCard(backgroundColor: privateTasks > 0 ? Brand.primary.opacity(0.05) : Brand.secondarySystemGroupedBackground) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(privateTasks > 0 ? Brand.primary.opacity(0.12) : Color.primary.opacity(0.05))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: privateTasks > 0 ? "shield.checkered" : "shield")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(privateTasks > 0 ? Brand.primary : .secondary)
                }
                
                VStack(spacing: 4) {
                    Text("Privacy Shield")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text(privateTasks > 0
                         ? "\(privateTasks) task\(privateTasks == 1 ? " is" : "s are") protected"
                         : "No tasks are currently private")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Privacy Stats
    private var privacyStats: some View {
        HStack(spacing: 16) {
            statCard(value: "\(privateTasks)", label: "Private", icon: "lock.fill", color: Brand.privacy)
            statCard(value: "\(publicTasks)", label: "Public", icon: "globe", color: Brand.primary)
            statCard(value: "\(privacyPercentage)%", label: "Protected", icon: "shield.fill", color: .green)
        }
    }
    
    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        LockInCard {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(label)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Helper Views
    
    private func privacySection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .textCase(.uppercase)
            }
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
            
            LockInCard {
                VStack(spacing: 16) {
                    content()
                }
            }
        }
    }
    
    private func settingsRow(title: String, icon: String, color: Color = .primary) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(color == .primary ? Brand.primary : color)
            Text(title)
                .fontWeight(.medium)
                .foregroundColor(color)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("Privacy Dashboard") {
    NavigationStack {
        PrivacyDashboardView()
            .environmentObject(TaskStore())
            .environmentObject(BiometricAuthManager.shared)
    }
}
