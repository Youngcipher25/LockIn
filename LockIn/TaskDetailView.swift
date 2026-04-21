import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var bioAuth: BiometricAuthManager
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
    @State private var editedPriority: Priority = .medium
    @State private var editedNotes: String = ""
    @State private var editedIsPrivate: Bool = false
    @State private var showValidationError = false
    
    private let titleCharLimit = 200
    
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
        editedPriority = taskItem.priority
        editedNotes = taskItem.notes ?? ""
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
                if isEditing {
                    setupInitialState()
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
            // Title & Priority Card
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
                    
                    // Priority
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Priority")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            
                            HStack(spacing: 6) {
                                Image(systemName: taskItem.priority.icon)
                                    .foregroundColor(taskItem.priority.color)
                                Text(taskItem.priority.displayLabel)
                                    .font(.headline)
                                    .foregroundColor(taskItem.priority.color)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Scheduled For")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            
                            Text(taskItem.isPrivate && isPrivacyModeEnabled ? "Protected Time" : taskItem.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            
            // Notes Card
            if let notes = taskItem.notes, !notes.isEmpty {
                LockInCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        Text(taskItem.isPrivate && isPrivacyModeEnabled ? "Protected content" : notes)
                            .font(.body)
                            .foregroundColor(.primary)
                            .blur(radius: (taskItem.isPrivate && isPrivacyModeEnabled) ? 4 : 0)
                    }
                }
            }
            
            // Status Card
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
            
            // Created At
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                Text("Created \(taskItem.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Edit Mode
    private var editSection: some View {
        VStack(spacing: 20) {
            // Title
            LockInCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Update Title")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        
                        Spacer()
                        
                        Text("\(editedTitle.count)/\(titleCharLimit)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(editedTitle.count > titleCharLimit ? .red : .secondary)
                    }
                    
                    TextField("Task title", text: $editedTitle)
                        .font(.title3)
                        .fontWeight(.medium)
                        .onChange(of: editedTitle) { oldValue, newValue in
                            if newValue.count > titleCharLimit {
                                editedTitle = String(newValue.prefix(titleCharLimit))
                            }
                            if showValidationError && !editedTitle.isEmpty {
                                showValidationError = false
                            }
                        }
                    
                    if showValidationError {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                            Text("Task title cannot be empty.")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            
            // Priority
            LockInCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Priority")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 8) {
                        ForEach(Priority.allCases, id: \.self) { level in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    editedPriority = level
                                }
                                HapticManager.impact(.light)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: level.icon)
                                        .font(.caption)
                                    Text(level.displayLabel)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(editedPriority == level ? level.color.opacity(0.15) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(editedPriority == level ? level.color : Color.primary.opacity(0.08), lineWidth: editedPriority == level ? 1.5 : 1)
                                )
                                .foregroundColor(editedPriority == level ? level.color : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Date & Privacy
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
            
            // Notes
            LockInCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    ZStack(alignment: .topLeading) {
                        if editedNotes.isEmpty {
                            Text("Add any extra details or reminders…")
                                .font(.body)
                                .foregroundColor(.secondary.opacity(0.5))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $editedNotes)
                            .font(.body)
                            .frame(minHeight: 80, maxHeight: 150)
                            .scrollContentBackground(.hidden)
                    }
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
        // Validation (Functional Doc §5.2)
        guard !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            withAnimation(.spring()) {
                showValidationError = true
            }
            HapticManager.notification(.error)
            return
        }
        
        var updatedTask = taskItem
        updatedTask.title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTask.date = editedDate
        updatedTask.priority = editedPriority
        updatedTask.notes = editedNotes.isEmpty ? nil : editedNotes
        updatedTask.isPrivate = editedIsPrivate
        
        withAnimation {
            taskItem = updatedTask
            taskStore.update(updatedTask)
        }
    }
}

#Preview {
    NavigationStack {
        TaskDetailView(taskItem: TaskItem(title: "Preview Task", date: Date(), priority: .high, notes: "Some important notes here", completed: false))
            .environmentObject(TaskStore())
            .environmentObject(BiometricAuthManager.shared)
    }
}
