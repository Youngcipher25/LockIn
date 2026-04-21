import SwiftUI
import LocalAuthentication

// MARK: - Biometric Authentication Manager
final class BiometricAuthManager: ObservableObject {
    static let shared = BiometricAuthManager()
    
    @Published var isPrivateContentRevealed = false
    @Published var biometricType: LABiometryType = .none
    @Published var lastAuthDate: Date?
    
    @AppStorage("autoLockTimeout") var autoLockTimeout: Int = 5 // minutes, 0 = immediate re-lock
    @AppStorage("requireBiometricForPrivate") var requireBiometricForPrivate: Bool = true
    
    private var autoLockTimer: Timer?
    
    private init() {
        checkBiometricAvailability()
    }
    
    // MARK: - Biometric Availability
    
    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricType = context.biometryType
        } else {
            biometricType = .none
        }
    }
    
    var biometricIcon: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        default: return "lock.fill"
        }
    }
    
    var biometricLabel: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default: return "Passcode"
        }
    }
    
    // MARK: - Authentication
    
    func authenticate(reason: String = "Reveal private tasks", completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"
        
        var error: NSError?
        
        // Check if biometrics or passcode is available
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    if success {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            self.isPrivateContentRevealed = true
                            self.lastAuthDate = Date()
                        }
                        self.startAutoLockTimer()
                        HapticManager.notification(.success)
                    } else {
                        HapticManager.notification(.error)
                    }
                    completion(success)
                }
            }
        } else {
            // No biometrics or passcode available — allow access
            DispatchQueue.main.async {
                self.isPrivateContentRevealed = true
                completion(true)
            }
        }
    }
    
    // MARK: - Auto-Lock Timer
    
    func lockPrivateContent() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isPrivateContentRevealed = false
            lastAuthDate = nil
        }
        autoLockTimer?.invalidate()
        autoLockTimer = nil
        HapticManager.impact(.rigid)
    }
    
    private func startAutoLockTimer() {
        autoLockTimer?.invalidate()
        
        guard autoLockTimeout > 0 else {
            // 0 means lock immediately when leaving the view — handled by onDisappear
            return
        }
        
        let interval = TimeInterval(autoLockTimeout * 60)
        autoLockTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.lockPrivateContent()
            }
        }
    }
    
    // MARK: - Visibility Logic
    
    /// Returns true if the given task's content should be hidden (blurred)
    func shouldBlurTask(_ task: TaskItem) -> Bool {
        guard task.isPrivate else { return false }
        guard requireBiometricForPrivate else { return false }
        return !isPrivateContentRevealed
    }
}
