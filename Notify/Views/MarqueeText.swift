import SwiftUI

/// Single-line text that ping-pong scrolls when it overflows `maxWidth`.
/// When the text fits, the frame hugs it so the parent's alignment applies.
/// Give it an `.id` keyed to the content so a track change resets the scroll.
///
/// With Reduce Motion on it never scrolls: the text truncates and the full
/// string stays reachable through the tooltip.
struct MarqueeText: View {
    var text: String
    var font: Font
    var maxWidth: CGFloat
    var speed: Double = 30
    var fadeEdges: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var textWidth: CGFloat = 0
    @State private var offset: CGFloat = 0

    private var overflows: Bool {
        textWidth > maxWidth
    }

    var body: some View {
        if reduceMotion {
            Text(text)
                .font(font)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: maxWidth, alignment: .leading)
                .help(text)
        } else {
            scrollingText
        }
    }

    /// Space between the text and the copy that follows it in.
    private static let gap: CGFloat = 32
    /// Rest at the start of each pass, so the title is readable before it moves.
    private static let pause: Duration = .seconds(2)

    /// Scrolls the whole string off to the leading edge with a second copy
    /// following it in, then snaps back to the identical start position and
    /// rests. Unlike a ping-pong over just the overflow, a string that is only
    /// a few points too wide moves at the same pace as a long one instead of
    /// jittering back and forth over those few points.
    private var scrollingText: some View {
        HStack(spacing: Self.gap) {
            label
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { width in
                    textWidth = width
                }
            if overflows {
                label
                    .accessibilityHidden(true)
            }
        }
        .fixedSize()
        .task(id: ScrollKey(text: text, textWidth: textWidth, maxWidth: maxWidth)) {
            offset = 0
            guard overflows, speed > 0 else { return }

            let distance = textWidth + Self.gap
            let duration = Double(distance) / speed
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.pause)
                guard !Task.isCancelled else { return }
                withAnimation(.linear(duration: duration)) {
                    offset = -distance
                }
                try? await Task.sleep(for: .seconds(duration))
                guard !Task.isCancelled else { return }
                // The copy now sits exactly where the original started, so
                // the unanimated reset is invisible.
                offset = 0
            }
        }
        .offset(x: offset)
        .frame(width: textWidth == 0 ? nil : min(textWidth, maxWidth), alignment: .leading)
        .clipped()
        .mask {
            if fadeEdges, overflows {
                HStack(spacing: 0) {
                    // Leading fade only while moving; at rest it would dim
                    // the first letters.
                    LinearGradient(colors: [offset == 0 ? .black : .clear, .black], startPoint: .leading, endPoint: .trailing)
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

private extension MarqueeText {
    var label: some View {
        Text(text)
            .font(font)
            .lineLimit(1)
            .fixedSize()
    }
}

private struct ScrollKey: Equatable {
    let text: String
    let textWidth: CGFloat
    let maxWidth: CGFloat
}
