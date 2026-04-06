import SwiftUI

struct PrivacyDashboardView: View {
    
    @AppStorage("isPrivacyModeEnabled") private var isPrivacyModeEnabled = false
    
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    @AppStorage("autoLockTimer") private var autoLockTimer = 0
    
    @AppStorage("defaultPrivateTasks") private var defaultPrivateTasks = false
    @AppStorage("hidePrivateTaskTitles") private var hidePrivateTaskTitles = true
    
    @AppStorage("hideOnLockScreen") private var hideOnLockScreen = false
    @AppStorage("genericNotifications") private var genericNotifications = true
    
    @EnvironmentObject var taskStore: TaskStore
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Privacy Mode Hero
                LockInCard(backgroundColor: isPrivacyModeEnabled ? Brand.primary.opacity(0.05) : Brand.secondarySystemGroupedBackground) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(isPrivacyModeEnabled ? Brand.primary.opacity(0.12) : Color.primary.opacity(0.05))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: isPrivacyModeEnabled ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(isPrivacyModeEnabled ? Brand.primary : .secondary)
                        }
                        .scaleEffect(isPrivacyModeEnabled ? 1.1 : 1.0)
                        
                        VStack(spacing: 4) {
                            Text("Privacy Mode")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text(isPrivacyModeEnabled ? "Sensitive content is currently hidden." : "Everything is visible.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Toggle("", isOn: $isPrivacyModeEnabled.animation(.spring()))
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: Brand.primary))
                            .scaleEffect(1.1)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                }
                
                // MARK: - App Lock Section
                privacySection(title: "App Lock", icon: "faceid") {
                    Toggle(isOn: $isAppLockEnabled) {
                        Text("Enable Face ID / Passcode")
                            .fontWeight(.medium)
                    }
                    .tint(Brand.primary)
                    
                    if isAppLockEnabled {
                        Divider()
                        
                        Picker(selection: $autoLockTimer, label: Label("Auto-Lock", systemImage: "timer")) {
                            Text("Immediately").tag(0)
                            Text("After 1 minute").tag(1)
                            Text("After 15 minutes").tag(15)
                        }
                        .fontWeight(.medium)
                    }
                }
                
                // MARK: - Notification Privacy Section
                privacySection(title: "Notification Privacy", icon: "bell.badge.shield.fill") {
                    Toggle(isOn: .init(get: { 
                        UserDefaults.standard.bool(forKey: "hideNotificationDetails") 
                    }, set: { 
                        UserDefaults.standard.set($0, forKey: "hideNotificationDetails") 
                        NotificationManager.shared.updateAllNotifications(tasks: taskStore.tasks)
                    })) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Conceal Private Details")
                                .fontWeight(.medium)
                            Text("Hide titles on the Lock Screen")
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
                
                // MARK: - Private Tasks Section
                privacySection(title: "Task Default", icon: "lock.doc.fill") {
                    Toggle(isOn: $defaultPrivateTasks) {
                        Text("Default New to Private")
                            .fontWeight(.medium)
                    }
                    .tint(Brand.privacy)
                }
                
                // MARK: - Data Section
                privacySection(title: "Data Control", icon: "square.stack.3d.up.fill") {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        settingsRow(title: "Wipe All Data", icon: "trash", color: .red)
                    }
                }
                
                Text("LockIn uses local-only encryption. Your data never leaves this device.")
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
    }
}
