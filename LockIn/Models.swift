import Foundation
import SwiftUI
import UserNotifications

struct TaskItem: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var completed: Bool
    var isPrivate: Bool = false
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

