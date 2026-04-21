import SwiftUI

struct NewTaskView: View {
    @EnvironmentObject var taskStore: TaskStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var date = Date()
    @State private var priority: Priority = .medium
    @State private var notes = ""
    @State private var isPrivate = false
    @State private var showValidationError = false
    
    @AppStorage("defaultPrivateTasks") private var defaultPrivateTasks = false
    
    private let titleCharLimit = 200

    var body: some View {
        ZStack {
            Brand.systemGroupedBackground.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create Task")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("Ready to lock in a new goal?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    Button {
                        HapticManager.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title Input with character counter
                        LockInCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("What's on your mind?")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)
                                    
                                    Spacer()
                                    
                                    Text("\(title.count)/\(titleCharLimit)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(title.count > titleCharLimit ? .red : .secondary)
                                }
                                
                                TextField("e.g. Design update for LockIn", text: $title)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .submitLabel(.done)
                                    .onChange(of: title) { oldValue, newValue in
                                        if newValue.count > titleCharLimit {
                                            title = String(newValue.prefix(titleCharLimit))
                                        }
                                        if showValidationError && !title.isEmpty {
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
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                        
                        // Priority Picker
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
                                                priority = level
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
                                                    .fill(priority == level ? level.color.opacity(0.15) : Color.clear)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(priority == level ? level.color : Color.primary.opacity(0.08), lineWidth: priority == level ? 1.5 : 1)
                                            )
                                            .foregroundColor(priority == level ? level.color : .secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        // Date & Privacy
                        LockInCard {
                            VStack(spacing: 16) {
                                DatePicker(
                                    selection: $date,
                                    displayedComponents: [.date, .hourAndMinute]
                                ) {
                                    Label("Schedule", systemImage: "calendar")
                                        .fontWeight(.medium)
                                }
                                
                                Divider()
                                
                                Toggle(isOn: $isPrivate) {
                                    HStack {
                                        Label("Private Task", systemImage: "lock.fill")
                                            .fontWeight(.medium)
                                        Spacer()
                                        if isPrivate {
                                            Text("Protected")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(Brand.privacy)
                                        }
                                    }
                                }
                                .tint(Brand.privacy)
                            }
                        }
                        
                        // Notes
                        LockInCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Notes (Optional)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                
                                ZStack(alignment: .topLeading) {
                                    if notes.isEmpty {
                                        Text("Add any extra details or reminders…")
                                            .font(.body)
                                            .foregroundColor(.secondary.opacity(0.5))
                                            .padding(.top, 8)
                                            .padding(.leading, 4)
                                    }
                                    TextEditor(text: $notes)
                                        .font(.body)
                                        .frame(minHeight: 80, maxHeight: 150)
                                        .scrollContentBackground(.hidden)
                                }
                            }
                        }
                        
                        Text("Private tasks hide their titles when Privacy Mode is active or on the Lock Screen.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        // Save Button inside scroll area
                        PrimaryButton(title: "Create Task", icon: "plus.circle.fill") {
                            saveTask()
                        }
                        .padding(.top, 10)
                        .disabled(title.isEmpty)
                        .opacity(title.isEmpty ? 0.6 : 1.0)
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            isPrivate = defaultPrivateTasks
        }
    }
    
    private func saveTask() {
        // Validation: Block empty title (Functional Doc §5.2, AC1)
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            withAnimation(.spring()) {
                showValidationError = true
            }
            HapticManager.notification(.error)
            return
        }
        
        let task = TaskItem(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            priority: priority,
            notes: notes.isEmpty ? nil : notes,
            completed: false,
            createdAt: Date(),
            isPrivate: isPrivate
        )
        
        withAnimation(.spring()) {
            taskStore.add(task)
        }
        dismiss()
    }
}

#Preview("New Task") {
    NewTaskView()
        .environmentObject(TaskStore())
}
