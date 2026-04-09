import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var taskStore: TaskStore
    @Environment(\.dismiss) var dismiss
    
    @State var taskItem: TaskItem
    @AppStorage("isPrivacyModeEnabled") private var isPrivacyModeEnabled = false
    @State private var isEditing = false
    
    // Computed property for privacy-aware title
    private var displayedTitle: String {
        if taskItem.isPrivate && isPrivacyModeEnabled {
            return "🔒 Private Task"
        }
        return taskItem.title
    }
    
    // Form States
    @State private var editedTitle: String = ""
    @State private var editedDate: Date = Date()
    @State private var editedIsPrivate: Bool = false
    
    var body: some View {
        ZStack {
            Brand.systemGroupedBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                ScrollView {
                    VStack(spacing: 24) {
                        if isEditing {
                            editSection
                        } else {
                            viewSection
                        }
                        
                        actionSection
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupInitialState()
        }
    }
    
    private func setupInitialState() {
        editedTitle = taskItem.title
        editedDate = taskItem.date
        editedIsPrivate = taskItem.isPrivate
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Button {
                HapticManager.impact(.light)
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.primary.opacity(0.05)))
            }
            
            Spacer()
            
            Text(isEditing ? "Edit Task" : "Task Details")
                .font(.headline)
                .fontWeight(.bold)
            
            Spacer()
            
            Button {
                HapticManager.impact(.medium)
                if isEditing {
                    saveChanges()
                    NotificationManager.shared.updateAllNotifications(tasks: taskStore.tasks)
                }
                withAnimation(.spring()) {
                    isEditing.toggle()
                }
            } label: {
                Text(isEditing ? "Save" : "Edit")
                    .fontWeight(.bold)
                    .foregroundColor(isEditing ? .green : Brand.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(isEditing ? Color.green.opacity(0.1) : Brand.primary.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(Brand.systemGroupedBackground)
    }
    
    // MARK: - View Mode
    private var viewSection: some View {
        VStack(spacing: 20) {
            LockInCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Title")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            
                            Text(displayedTitle)
                                .font(.title2)
                                .fontWeight(.bold)
                                .blur(radius: (taskItem.isPrivate && isPrivacyModeEnabled) ? 4 : 0)
                        }
                        Spacer()
                        if taskItem.isPrivate {
                            Image(systemName: "lock.fill")
                                .font(.title3)
                                .foregroundColor(Brand.privacy)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scheduled For")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        Text(taskItem.isPrivate && isPrivacyModeEnabled ? "Protected Time" : taskItem.date.formatted(date: .complete, time: .shortened))
                            .font(.headline)
                    }
                }
            }
            
            LockInCard {
                HStack(spacing: 16) {
                    Circle()
                        .fill(taskItem.completed ? Color.green : Color.orange)
                        .frame(width: 12, height: 12)
                    
                    Text(taskItem.completed ? "Task Completed" : "Task In Progress")
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button {
                        HapticManager.notification(.success)
                        withAnimation {
                            var updatedTask = taskItem
                            updatedTask.completed.toggle()
                            taskItem = updatedTask
                            taskStore.update(updatedTask)
                        }
                    } label: {
                        Text(taskItem.completed ? "Undo" : "Complete")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(taskItem.completed ? Color.secondary : Brand.primary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
    
    // MARK: - Edit Mode
    private var editSection: some View {
        VStack(spacing: 20) {
            LockInCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Update Title")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    TextField("Task title", text: $editedTitle)
                        .font(.title3)
                        .fontWeight(.medium)
                }
            }
            
            LockInCard {
                VStack(spacing: 16) {
                    DatePicker(selection: $editedDate) {
                        Label("Schedule", systemImage: "calendar")
                            .fontWeight(.medium)
                    }
                    
                    Divider()
                    
                    Toggle(isOn: $editedIsPrivate) {
                        Label("Private Task", systemImage: "lock.fill")
                            .fontWeight(.medium)
                    }
                    .tint(Brand.privacy)
                }
            }
        }
    }
    
    // MARK: - Actions
    private var actionSection: some View {
        VStack(spacing: 16) {
            if !isEditing {
                Button {
                    HapticManager.notification(.warning)
                    taskStore.delete(taskItem)
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete Task")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }
    
    private func saveChanges() {
        var updatedTask = taskItem
        updatedTask.title = editedTitle
        updatedTask.date = editedDate
        updatedTask.isPrivate = editedIsPrivate
        
        withAnimation {
            taskItem = updatedTask
            taskStore.update(updatedTask)
        }
    }
}

#Preview {
    NavigationStack {
        TaskDetailView(taskItem: TaskItem(title: "Preview Task", date: Date(), completed: false))
            .environmentObject(TaskStore())
    }
}
