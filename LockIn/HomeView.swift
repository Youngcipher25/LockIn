import SwiftUI

struct HomeView: View {
    @EnvironmentObject var taskStore: TaskStore
    @State private var selectedFilter: TaskFilter = .today
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    // Privacy Settings
    @AppStorage("isPrivacyModeEnabled") private var isPrivacyModeEnabled = false
    @AppStorage("hidePrivateTaskTitles") private var hidePrivateTaskTitles = true

    // MARK: - Stats Logic
    private var todayStats: (completed: Int, total: Int, privacyRatio: Double) {
        let calendar = Calendar.current
        let todayTasks = taskStore.tasks.filter { calendar.isDateInToday($0.date) }
        let completed = todayTasks.filter { $0.completed }.count
        let privateTasks = todayTasks.filter { $0.isPrivate }.count
        let ratio = todayTasks.isEmpty ? 0 : Double(privateTasks) / Double(todayTasks.count)
        return (completed, todayTasks.count, ratio)
    }

    private var focusScore: Int {
        guard todayStats.total > 0 else { return 0 }
        return Int((Double(todayStats.completed) / Double(todayStats.total)) * 100)
    }

    private var filteredTasks: [TaskItem] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? startOfToday

        var tasks: [TaskItem]
        switch selectedFilter {
        case .today:
            tasks = taskStore.tasks.filter { task in
                !task.completed && task.date < endOfToday
            }
        case .upcoming:
            tasks = taskStore.tasks.filter { task in
                !task.completed && task.date >= endOfToday
            }
        case .completed:
            tasks = taskStore.tasks.filter { $0.completed }
        }

        if !searchText.isEmpty {
            tasks = tasks.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }

        return tasks.sorted { $0.date < $1.date }
    }

    @State private var isShowingNewTask = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Brand.systemGroupedBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Hero Header
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    statsSection
                    searchSection
                    filterSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(
                    Brand.systemGroupedBackground
                        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                )
                
                // MARK: - Task List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if filteredTasks.isEmpty {
                            emptyStateView
                                .padding(.top, 60)
                        } else {
                            ForEach(filteredTasks) { task in
                                TaskCardView(
                                    task: task,
                                    isPrivacyMode: isPrivacyModeEnabled,
                                    hidePrivateTitles: hidePrivateTaskTitles, // This parameter is still passed but its effect on title masking is removed in TaskCardView
                                    onToggle: {
                                        HapticManager.impact(.light)
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                            taskStore.toggle(task)
                                        }
                                    },
                                    onDelete: {
                                        HapticManager.notification(.warning)
                                        withAnimation { taskStore.delete(task) }
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                                    removal: .opacity.combined(with: .move(edge: .trailing))
                                ))
                            }
                        }
                    }
                    .padding(20)
                }
            }
            
            // MARK: - Floating Add Button
            Button {
                HapticManager.impact(.medium)
                isShowingNewTask = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Brand.primary)
                        .frame(width: 60, height: 60)
                        .shadow(color: Brand.primary.opacity(0.4), radius: 12, x: 0, y: 6)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.trailing, 25)
            .padding(.bottom, 25)
        }
        .navigationTitle("Lock In")
        .sheet(isPresented: $isShowingNewTask) {
            NewTaskView()
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date().formatted(.dateTime.weekday(.wide).day().month()))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            Spacer()

            Button {
                withAnimation(.spring()) {
                    isPrivacyModeEnabled.toggle()
                    NotificationManager.shared.updateAllNotifications(tasks: taskStore.tasks)
                }
                HapticManager.impact(.rigid)
            } label: {
                Image(systemName: isPrivacyModeEnabled ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isPrivacyModeEnabled ? .indigo : .primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(isPrivacyModeEnabled ? Color.indigo.opacity(0.1) : Color.primary.opacity(0.05))
                    )
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        LockInCard {
            HStack(spacing: 20) {
                // Focus Graph
                FocusGraphView(score: focusScore)
                    .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 30) {
                        statItem(
                            title: "Task Flow",
                            value: "\(todayStats.completed)/\(todayStats.total)",
                            icon: "sparkles",
                            color: .orange
                        )
                        
                        statItem(
                            title: "Privacy Hub",
                            value: "\(Int(todayStats.privacyRatio * 100))%",
                            icon: "lock.shield.fill",
                            color: Brand.privacy
                        )
                    }
                    
                    Text("Today's Focus Score is \(focusScore)%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Brand.primary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private func statItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                Text(title)
                    .font(.system(size: 9, weight: .black))
                    .textCase(.uppercase)
            }
            .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
    }

    // MARK: - Search
    private var searchSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)

            TextField("Search tasks", text: $searchText)
                .font(.body)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    isSearchFocused = false
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Brand.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.04), lineWidth: 1)
        )
    }

    // MARK: - Filter
    private var filterSection: some View {
        HStack(spacing: 8) {
            ForEach(TaskFilter.allCases, id: \.self) { filter in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFilter = filter
                    }
                    HapticManager.impact(.light)
                } label: {
                    Text(filter.rawValue.capitalized)
                        .font(.subheadline)
                        .fontWeight(selectedFilter == filter ? .bold : .medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedFilter == filter ? Brand.primary : Color.clear)
                        )
                        .foregroundColor(selectedFilter == filter ? .white : .secondary)
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: emptyStateIcon)
                .font(.system(size: 64))
                .foregroundStyle(Brand.primary.opacity(0.2))
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.headline)
                    .fontWeight(.bold)

                Text(emptyStateMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
        }
    }

    private var emptyStateIcon: String {
        switch selectedFilter {
        case .today: return "checkmark.seal.fill"
        case .upcoming: return "calendar.badge.plus"
        case .completed: return "archivebox.fill"
        }
    }

    private var emptyStateTitle: String {
        switch selectedFilter {
        case .today: return "All Caught Up"
        case .upcoming: return "Clear Skies"
        case .completed: return "No History"
        }
    }

    private var emptyStateMessage: String {
        switch selectedFilter {
        case .today: return "You've completed everything scheduled for today. Time to relax."
        case .upcoming: return "No upcoming tasks in your schedule. Enjoy the quiet."
        case .completed: return "You haven't completed any tasks recently."
        }
    }
}

// MARK: - Task Filter
private enum TaskFilter: String, CaseIterable {
    case today, upcoming, completed
}

// MARK: - Task Card View
private struct TaskCardView: View {
    let task: TaskItem
    let isPrivacyMode: Bool
    let hidePrivateTitles: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var showPlaceholder: Bool {
        // No longer masking inside the app, but keeping this logic for the lock icon visibility
        task.isPrivate
    }

    var body: some View {
        LockInCard {
            HStack(spacing: 16) {
                Button(action: onToggle) {
                    Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(task.completed ? .green : .secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if task.isPrivate {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundColor(Brand.privacy)
                        }
                        
                        Text(task.title)
                            .font(.body)
                            .fontWeight(.semibold)
                            .strikethrough(task.completed, color: .secondary)
                            .foregroundStyle(task.completed ? .secondary : .primary)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(task.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Circle())
                }
            }
        }
    }
}

#Preview("Full App") {
    MainTabView()
        .environmentObject(TaskStore())
}

// MARK: - Components

struct FocusGraphView: View {
    let score: Int
    
    var body: some View {
        ZStack {
            // Background Track
            Circle()
                .stroke(Color.primary.opacity(0.05), lineWidth: 8)
            
            // Progress Ring
            Circle()
                .trim(from: 0, to: Double(score) / 100.0)
                .stroke(
                    LinearGradient(
                        colors: [Brand.primary, Brand.primary.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            VStack(spacing: -2) {
                Text("\(score)%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text("FOCUS")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.secondary)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: score)
    }
}
