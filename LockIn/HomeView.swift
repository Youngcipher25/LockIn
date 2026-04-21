import SwiftUI

struct HomeView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var bioAuth: BiometricAuthManager
    @State private var selectedFilter: TaskFilter = .today
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    // Privacy Settings
    @AppStorage("isPrivacyModeEnabled") private var isPrivacyModeEnabled = false

    // MARK: - Dashboard Stats (Functional Doc §5.10)
    private var dashboardStats: (total: Int, pending: Int, completed: Int) {
        let total = taskStore.tasks.count
        let completed = taskStore.tasks.filter { $0.completed }.count
        let pending = total - completed
        return (total, pending, completed)
    }

    private var focusScore: Int {
        guard dashboardStats.total > 0 else { return 0 }
        return Int((Double(dashboardStats.completed) / Double(dashboardStats.total)) * 100)
    }
    
    private var privateTaskCount: Int {
        taskStore.tasks.filter { $0.isPrivate }.count
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
                    
                    // Private tasks unlock banner
                    if privateTaskCount > 0 && bioAuth.requireBiometricForPrivate {
                        privateBanner
                    }
                    
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
                                    isBlurred: bioAuth.shouldBlurTask(task),
                                    onToggle: {
                                        // Don't allow toggling blurred tasks
                                        if bioAuth.shouldBlurTask(task) {
                                            bioAuth.authenticate { _ in }
                                            return
                                        }
                                        HapticManager.impact(.light)
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                            taskStore.toggle(task)
                                        }
                                    },
                                    onDelete: {
                                        HapticManager.notification(.warning)
                                        withAnimation { taskStore.delete(task) }
                                    },
                                    onTapBlurred: {
                                        bioAuth.authenticate { _ in }
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

    // MARK: - Stats Section (Functional Doc §5.10 — total, pending, completed)
    private var statsSection: some View {
        LockInCard {
            HStack(spacing: 20) {
                // Focus Graph
                FocusGraphView(score: focusScore)
                    .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 20) {
                        statItem(
                            title: "Total",
                            value: "\(dashboardStats.total)",
                            icon: "list.bullet.circle.fill",
                            color: Brand.primary
                        )
                        
                        statItem(
                            title: "Pending",
                            value: "\(dashboardStats.pending)",
                            icon: "clock.fill",
                            color: .orange
                        )
                        
                        statItem(
                            title: "Done",
                            value: "\(dashboardStats.completed)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                    }
                    
                    Text("Focus Score: \(focusScore)%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Brand.primary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Private Tasks Banner
    private var privateBanner: some View {
        Button {
            if bioAuth.isPrivateContentRevealed {
                bioAuth.lockPrivateContent()
            } else {
                bioAuth.authenticate { _ in }
            }
        } label: {
            LockInCard(backgroundColor: bioAuth.isPrivateContentRevealed ? Color.green.opacity(0.05) : Brand.privacy.opacity(0.08)) {
                HStack(spacing: 12) {
                    Image(systemName: bioAuth.isPrivateContentRevealed ? "lock.open.fill" : bioAuth.biometricIcon)
                        .font(.title3)
                        .foregroundColor(bioAuth.isPrivateContentRevealed ? .green : Brand.privacy)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(bioAuth.isPrivateContentRevealed ? Color.green.opacity(0.1) : Brand.privacy.opacity(0.15))
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(bioAuth.isPrivateContentRevealed ? "Private Tasks Visible" : "\(privateTaskCount) Private Task\(privateTaskCount == 1 ? "" : "s") Hidden")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(bioAuth.isPrivateContentRevealed ? "Tap to lock again" : "Tap to unlock with \(bioAuth.biometricLabel)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: bioAuth.isPrivateContentRevealed ? "lock.fill" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
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
        if !searchText.isEmpty { return "magnifyingglass" }
        switch selectedFilter {
        case .today: return "checkmark.seal.fill"
        case .upcoming: return "calendar.badge.plus"
        case .completed: return "archivebox.fill"
        }
    }

    private var emptyStateTitle: String {
        if !searchText.isEmpty { return "No Results" }
        switch selectedFilter {
        case .today: return "All Caught Up"
        case .upcoming: return "Clear Skies"
        case .completed: return "No History"
        }
    }

    // Functional Doc §5.11, AC4: "No tasks match your search."
    private var emptyStateMessage: String {
        if !searchText.isEmpty { return "No tasks match your search." }
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
    let isBlurred: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onTapBlurred: () -> Void

    var body: some View {
        Group {
            if isBlurred {
                blurredCard
            } else {
                normalCard
            }
        }
    }
    
    // MARK: - Blurred (Locked) Card
    private var blurredCard: some View {
        Button(action: onTapBlurred) {
            LockInCard {
                HStack(spacing: 16) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(Brand.privacy)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundColor(Brand.privacy)
                            
                            Text("Private Task")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        
                        Text("Tap to authenticate and reveal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: BiometricAuthManager.shared.biometricIcon)
                        .font(.title3)
                        .foregroundColor(Brand.privacy.opacity(0.6))
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Normal (Visible) Card
    private var normalCard: some View {
        NavigationLink(destination: TaskDetailView(taskItem: task)) {
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
                                Image(systemName: "lock.open.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                            
                            Text(task.title)
                                .font(.body)
                                .fontWeight(.semibold)
                                .strikethrough(task.completed, color: .secondary)
                                .foregroundStyle(task.completed ? .secondary : .primary)
                        }

                        HStack(spacing: 10) {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                Text(task.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                            
                            // Priority badge
                            HStack(spacing: 3) {
                                Image(systemName: task.priority.icon)
                                    .font(.system(size: 9))
                                Text(task.priority.displayLabel)
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(task.priority.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(task.priority.color.opacity(0.1))
                            .clipShape(Capsule())
                        }
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
                    .buttonStyle(.plain)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("Full App") {
    MainTabView()
        .environmentObject(TaskStore())
        .environmentObject(BiometricAuthManager.shared)
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
