import SwiftUI

/// Single-line text that ping-pong scrolls when it overflows `maxWidth`.
/// When the text fits, the frame hugs it so the parent's alignment applies.
/// Give it an `.id` keyed to the content so a track change resets the scroll.
struct MarqueeText: View {
    var text: String
    var font: Font
    var maxWidth: CGFloat
    var speed: Double = 18
    var fadeEdges: Bool = false

    @State private var textWidth: CGFloat = 0
    @State private var offset: CGFloat = 0

    private var overflows: Bool {
        textWidth > maxWidth
    }

    var body: some View {
        Text(text)
            .font(font)
            .lineLimit(1)
            .fixedSize()
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                textWidth = width
                offset = 0
                guard width > maxWidth else { return }
                let distance = width - maxWidth
                withAnimation(
                    .linear(duration: Double(distance) / speed)
                        .repeatForever(autoreverses: true)
                        .delay(1.2)
                ) {
                    offset = -distance
                }
            }
            .offset(x: offset)
            .frame(width: textWidth == 0 ? nil : min(textWidth, maxWidth), alignment: .leading)
            .clipped()
            .mask {
                if fadeEdges, overflows {
                    HStack(spacing: 0) {
                        LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                            .frame(width: 12)
                        Rectangle().fill(.black)
                        LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: 12)
                    }
                } else {
                    Rectangle().fill(.black)
                }
            }
    }
}
