import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var bioAuth: BiometricAuthManager
    @State private var selectedDate = Date()
    
    @AppStorage("isPrivacyModeEnabled") private var isPrivacyModeEnabled = false

    var tasksForSelectedDate: [TaskItem] {
        taskStore.tasks.filter {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Calendar Card
                LockInCard {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(Brand.primary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Tasks Summary
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Tasks")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("\(tasksForSelectedDate.count) total")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 4)
                    
                    if tasksForSelectedDate.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary.opacity(0.4))
                            
                            Text("No tasks scheduled")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(
                            RoundedRectangle(cornerRadius: Brand.cornerRadius)
                                .stroke(Color.primary.opacity(0.05), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        )
                    } else {
                        VStack(spacing: 12) {
                            ForEach(tasksForSelectedDate) { task in
                                CalendarTaskRow(
                                    task: task,
                                    isBlurred: bioAuth.shouldBlurTask(task),
                                    onToggle: {
                                        if bioAuth.shouldBlurTask(task) {
                                            bioAuth.authenticate { _ in }
                                            return
                                        }
                                        HapticManager.impact(.light)
                                        withAnimation { taskStore.toggle(task) }
                                    },
                                    onTapBlurred: {
                                        bioAuth.authenticate { _ in }
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(20)
                
                Spacer()
            }
        }
        .navigationTitle("Calendar")
    }
}

private struct CalendarTaskRow: View {
    let task: TaskItem
    let isBlurred: Bool
    let onToggle: () -> Void
    let onTapBlurred: () -> Void

    var body: some View {
        if isBlurred {
            Button(action: onTapBlurred) {
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(Brand.privacy)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Private Task")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Authenticate to reveal")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: BiometricAuthManager.shared.biometricIcon)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Brand.secondarySystemGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Brand.privacy.opacity(0.2), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(destination: TaskDetailView(taskItem: task)) {
                HStack(spacing: 12) {
                    Button(action: onToggle) {
                        Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.completed ? .green : .secondary)
                    }
                    .buttonStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            if task.isPrivate {
                                Image(systemName: "lock.open.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                            Text(task.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .strikethrough(task.completed)
                                .foregroundColor(task.completed ? .secondary : .primary)
                        }
                        
                        HStack(spacing: 8) {
                            Text(task.date.formatted(date: .omitted, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            
                            // Priority badge
                            HStack(spacing: 2) {
                                Image(systemName: task.priority.icon)
                                    .font(.system(size: 8))
                                Text(task.priority.displayLabel)
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(task.priority.color)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(task.priority.color.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(Brand.secondarySystemGroupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview("Full App") {
    MainTabView()
        .environmentObject(TaskStore())
        .environmentObject(BiometricAuthManager.shared)
}
