import SwiftUI

/// Circular transport button shared by the menu player and radio views.
/// A real `Button` so keyboard focus + Return activate it and VoiceOver
/// reports it correctly.
struct PlayerControlButton: View {
    let systemName: String
    var font: Font = .body
    let accessibilityLabel: String
    var accessibilityHint: String? = nil
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(font)
                .foregroundStyle(.primary)
                .padding(10)
                .background(
                    Circle()
                        .fill(.primary.opacity(hovering ? 0.2 : 0.1))
                        .stroke(.primary.opacity(0.15), lineWidth: 1)
                )
                .scaleEffect(hovering ? 1.08 : 1.0)
                .shadow(color: .primary.opacity(0.2), radius: hovering ? 4 : 0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                self.hovering = hovering
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint ?? "")
    }
}
