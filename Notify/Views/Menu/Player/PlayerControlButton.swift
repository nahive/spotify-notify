import SwiftUI

/// Transport button shared by the menu player and radio views: a bare glyph
/// with a soft circular highlight on hover. A real `Button` so keyboard
/// focus + Return activate it and VoiceOver reports it correctly.
struct PlayerControlButton: View {
    let systemName: String
    var font: Font = .system(size: 18, weight: .semibold)
    var size: CGFloat = 36
    let accessibilityLabel: LocalizedStringKey
    var accessibilityHint: LocalizedStringKey? = nil
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(font)
                .foregroundStyle(.primary)
                .frame(width: size, height: size)
                .background(.primary.opacity(hovering ? 0.1 : 0), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(PressScaleButtonStyle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                self.hovering = hovering
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint.map { Text($0) } ?? Text(verbatim: ""))
    }
}

/// Shrinks and dims slightly while pressed.
struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
