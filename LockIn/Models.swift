import Foundation
import SwiftUI
import UserNotifications

// MARK: - Priority Enum (Architecture Doc §2.2)
enum Priority: String, Codable, CaseIterable, Comparable {
    case low
    case medium
    case high
    
    var displayLabel: String {
        rawValue.capitalized
    }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle.fill"
        case .medium: return "minus.circle.fill"
        case .high: return "exclamationmark.circle.fill"
        }
    }
    
    private var sortOrder: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
    
    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - TaskItem Model (Architecture Doc §2.2)
struct TaskItem: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var priority: Priority = .medium
    var notes: String? = nil
    var completed: Bool = false
    var createdAt: Date = Date()
    var isPrivate: Bool = false
    
    // Backward-compatible decoding: old tasks without priority/notes/createdAt still load
    enum CodingKeys: String, CodingKey {
        case id, title, date, priority, notes, completed, createdAt, isPrivate
    }
    
    init(id: UUID = UUID(), title: String, date: Date, priority: Priority = .medium, notes: String? = nil, completed: Bool = false, createdAt: Date = Date(), isPrivate: Bool = false) {
        self.id = id
        self.title = title
        self.date = date
        self.priority = priority
        self.notes = notes
        self.completed = completed
        self.createdAt = createdAt
        self.isPrivate = isPrivate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(Date.self, forKey: .date)
        priority = try container.decodeIfPresent(Priority.self, forKey: .priority) ?? .medium
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        completed = try container.decodeIfPresent(Bool.self, forKey: .completed) ?? false
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        isPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivate) ?? false
    }
}

final class TaskStore: ObservableObject {
    @Published var tasks: [TaskItem] = [] {
        didSet {
            saveTasks()
            NotificationManager.shared.updateAllNotifications(tasks: tasks)
        }
    }

    private var storageURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("lockin_vault.json")
    }

    init() {
        migrateFromUserDefaults()
        loadTasks()
    }

    func add(_ task: TaskItem) {
        tasks.append(task)
    }

    func toggle(_ task: TaskItem) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx].completed.toggle()
        }
    }

    func update(_ task: TaskItem) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
        }
    }

    func delete(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
    }

    func clearAll() {
        tasks.removeAll()
    }

    // MARK: - Persistence Logic
    
    private func saveTasks() {
        do {
            let data = try JSONEncoder().encode(tasks)
            try data.write(to: storageURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("Failed to save tasks: \(error.localizedDescription)")
        }
    }

    private func loadTasks() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: storageURL)
            let decoded = try JSONDecoder().decode([TaskItem].self, from: data)
            tasks = decoded
        } catch {
            print("Failed to load tasks: \(error.localizedDescription)")
        }
    }
    
    /// Seemlessly migrates data from the old UserDefaults system if it exists
    private func migrateFromUserDefaults() {
        let key = "TASK_STORAGE"
        if let oldData = UserDefaults.standard.data(forKey: key) {
            do {
                let decoded = try JSONDecoder().decode([TaskItem].self, from: oldData)
                self.tasks = decoded
                saveTasks() // Save to new file
                UserDefaults.standard.removeObject(forKey: key) // Clean up old storage
            } catch {
                print("Migration failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Storage Metrics (Dynamic)
    
    /// Returns the size of the task data file in bytes
    var dataFileSize: Int64 {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return 0 }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: storageURL.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    /// Returns the total size of all files in the app's Documents directory
    var totalDocumentsSize: Int64 {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return folderSize(at: documentsPath)
    }
    
    private func folderSize(at url: URL) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }
}

// MARK: - Notification Management
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    @AppStorage("hideNotificationDetails") private var hideNotificationDetails = true
    @AppStorage("isPrivacyModeEnabled") private var privacyModeEnabled = false
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(for task: TaskItem) {
        // Don't schedule for completed tasks
        guard !task.completed else {
            cancelNotification(for: task)
            return
        }
        
        // Don't schedule if date is in the past
        guard task.date > Date() else { return }
        
        let content = UNMutableNotificationContent()
        
        // Privacy Logic: Mask content if task is private AND (privacy mode is on OR conceal setting is on)
        if task.isPrivate && (privacyModeEnabled || hideNotificationDetails) {
            content.title = "🔒 Private Task"
            content.body = "You have a protected reminder."
        } else {
            content.title = task.title
            content.body = "Time to lock in: \(task.title)"
        }
        
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Successfully scheduled: \(task.title)")
            }
        }
    }
    
    func cancelNotification(for task: TaskItem) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }
    
    func updateAllNotifications(tasks: [TaskItem]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        for task in tasks {
            scheduleNotification(for: task)
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              willPresent notification: UNNotification, 
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Allow notifications while the app is in the foreground
        completionHandler([.banner, .list, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              didReceive response: UNNotificationResponse, 
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        completionHandler()
    }
}
