import SwiftUI

struct AppLockView: View {
    @Binding var isUnlocked: Bool
    @State private var input: [Int] = []
    private let passcode: [Int] = [1,2,3,4]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Enter Passcode").font(.title2).bold()
                Text("Authenticate to unlock Private Organizer").font(.subheadline).foregroundStyle(.secondary)
            }
            HStack(spacing: 12) {
                ForEach(0..<4, id: \.self) { idx in
                    Circle()
                        .fill(idx < input.count ? Color.primary : Color.clear)
                        .overlay(Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                        .frame(width: 16, height: 16)
                        .animation(.easeInOut, value: input)
                }
            }
            VStack(spacing: 12) {
                ForEach([[1,2,3],[4,5,6],[7,8,9]], id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { num in
                            keypadButton(title: String(num)) { tap(num) }
                        }
                    }
                }
                HStack(spacing: 12) {
                    keypadButton(title: "⌫") { backspace() }
                    keypadButton(title: "0") { tap(0) }
                    keypadButton(title: "Clear") { clear() }
                }
            }
            .padding(.top, 8)
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private func keypadButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title3)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
        }
        .buttonStyle(.plain)
    }

    private func tap(_ number: Int) {
        guard input.count < 4 else { return }
        input.append(number)
        if input.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if input == passcode { isUnlocked = true } else { input.removeAll() }
            }
        }
    }

    private func backspace() { if !input.isEmpty { _ = input.removeLast() } }
    private func clear() { input.removeAll() }
}

#Preview {
    struct Wrapper: View {
        @State var unlocked = false
        var body: some View { AppLockView(isUnlocked: $unlocked) }
    }
    return Wrapper()
}
