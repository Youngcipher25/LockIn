import SwiftUI

struct NewTaskView: View {
    @EnvironmentObject var taskStore: TaskStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var date = Date()
    @State private var isPrivate = false
    
    @AppStorage("defaultPrivateTasks") private var defaultPrivateTasks = false

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
                        // Title Input
                        LockInCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("What's on your mind?")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                
                                TextField("e.g. Design update for LockIn", text: $title)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        if !title.isEmpty { saveTask() }
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
        guard !title.isEmpty else { return }
        
        let task = TaskItem(
            title: title,
            date: date,
            completed: false,
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

