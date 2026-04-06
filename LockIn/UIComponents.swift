import SwiftUI
import UIKit

// MARK: - Design System Tokens
enum Brand {
    static let primary = Color.indigo
    static let secondary = Color.blue
    static let privacy = Color.yellow
    static let cornerRadius: CGFloat = 20
    static let cardShadow = Color.black.opacity(0.06)
    static let borderOpacity: Double = 0.1
    
    // Semantic Backgrounds
    static var systemGroupedBackground: Color {
        Color(uiColor: .systemGroupedBackground)
    }
    
    static var secondarySystemGroupedBackground: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }
}

// MARK: - Components

/// A modern, elevated card with subtle border and shadow
struct LockInCard<Content: View>: View {
    let content: Content
    var backgroundColor: Color? = nil
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    init(backgroundColor: Color, @ViewBuilder content: () -> Content) {
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Brand.cornerRadius, style: .continuous)
                    .fill(backgroundColor ?? Brand.secondarySystemGroupedBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Brand.cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(Brand.borderOpacity), lineWidth: 0.5)
            )
            .shadow(color: Brand.cardShadow, radius: 12, x: 0, y: 6)
    }
}

struct FeatureCard: View {
    var icon: String
    var title: String
    var description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Brand.primary)
                .frame(width: 48, height: 48)
                .background(Brand.primary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Brand.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: Brand.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Brand.cornerRadius, style: .continuous)
                .stroke(Color.primary.opacity(Brand.borderOpacity), lineWidth: 0.5)
        )
    }
}

struct PrimaryButton: View {
    var title: String
    var icon: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            HapticManager.impact(.medium)
            action?()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Brand.primary)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Brand.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SecondaryButton: View {
    var title: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            HapticManager.impact(.light)
            action?()
        }) {
            Text(title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(uiColor: .secondarySystemBackground))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Helper Styles

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Utilities

enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

