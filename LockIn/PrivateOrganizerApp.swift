import SwiftUI

@main
struct PrivateOrganizerApp: App {
    @StateObject private var taskStore = TaskStore()
    @AppStorage("darkMode") private var isDarkMode = false
    
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(taskStore)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

struct AppRootView: View {
    @EnvironmentObject var taskStore: TaskStore
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @AppStorage("darkMode") private var isDarkMode = false
    @State private var isUnlocked = false

    var body: some View {
        ZStack {
            if !isAuthenticated {
                LoginView()
            } else if !isUnlocked {
                AppLockView(isUnlocked: $isUnlocked)
            } else {
                MainTabView()
            }
        }
        .animation(.spring(), value: isAuthenticated)
        .animation(.spring(), value: isUnlocked)
    }
}

// MARK: - Auth Views
struct LoginView: View {
    @EnvironmentObject var taskStore: TaskStore
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    
    @State private var email = ""
    @State private var isShowingOTP = false
    @State private var isSignup = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Brand.systemGroupedBackground.ignoresSafeArea()
                
                VStack {
                    Circle()
                        .fill(Brand.primary.opacity(0.05))
                        .frame(width: 400, height: 400)
                        .offset(x: 150, y: -200)
                    Spacer()
                }
                
                VStack(spacing: 32) {
                    Spacer()
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Brand.primary)
                                .frame(width: 80, height: 80)
                                .shadow(color: Brand.primary.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            Image(systemName: "lock.fill")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                        }
                        VStack(spacing: 8) {
                            Text(isSignup ? "Create Account" : "Welcome Back")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            Text(isSignup ? "Start your private productivity journey." : "Securely access your tasks and reminders.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    
                    VStack(spacing: 20) {
                        LockInCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email Address")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(Brand.primary)
                                    TextField("name@example.com", text: $email)
                                        .textInputAutocapitalization(.never)
                                        .keyboardType(.emailAddress)
                                }
                            }
                        }
                        PrimaryButton(title: isSignup ? "Sign Up" : "Sign In", icon: "arrow.right.circle.fill") {
                            isShowingOTP = true
                        }
                        .disabled(email.isEmpty || !email.contains("@"))
                        .opacity(email.isEmpty || !email.contains("@") ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 20)
                    
                    Button {
                        withAnimation { isSignup.toggle() }
                    } label: {
                        HStack {
                            Text(isSignup ? "Already have an account?" : "Don't have an account?")
                            Text(isSignup ? "Sign In" : "Create one").fontWeight(.bold)
                        }
                        .font(.footnote)
                    }
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $isShowingOTP) {
                OTPVerificationView(email: email)
            }
        }
    }
}

struct OTPVerificationView: View {
    let email: String
    @AppStorage("isAuthenticated") private var isAuthenticated = false
    @State private var otpCode = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            Brand.systemGroupedBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Brand.primary.opacity(0.1)).frame(width: 80, height: 80)
                        Image(systemName: "shield.text.badge.checkmark").font(.largeTitle).foregroundColor(Brand.primary)
                    }
                    Text("Verify Email").font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("We sent a code to \(email)").font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                TextField("000000", text: $otpCode)
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .padding()
                    .background(Brand.secondarySystemGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 40)
                
                Spacer()
                
                PrimaryButton(title: "Verify & Continue", icon: "checkmark.shield.fill") {
                    withAnimation { isAuthenticated = true }
                }
                .disabled(otpCode.count != 6)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .onAppear { isFocused = true }
    }
}
