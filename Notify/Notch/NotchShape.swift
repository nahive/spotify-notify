import SwiftUI

/// The MacBook notch outline: top corners flare outward, bottom corners round in.
/// Corner reach is controlled separately from corner rise (`topSpread` /
/// `bottomSpread` vs `topRadius` / `bottomRadius`), so a corner can be a long
/// shallow ramp instead of a tight quarter-round. As the straight side wall
/// between the corners shrinks to nothing, each side blends continuously into a
/// single sigmoid sweep from the screen edge to the pill bottom, so a short
/// pill reads as one smooth wave rather than two stacked rounds — and a pill
/// growing into a card morphs without ever popping between constructions.
struct NotchShape: Shape {
    var topRadius: CGFloat
    /// Horizontal reach of the top flare. Larger than `topRadius` stretches the
    /// flare into a gentle ramp.
    var topSpread: CGFloat
    /// Vertical rise of the bottom corners.
    var bottomRadius: CGFloat
    /// Horizontal reach of the bottom corners. Larger than `bottomRadius` makes
    /// the corner a long, gentle sweep rather than a round.
    var bottomSpread: CGFloat
    /// Handle length as a fraction of the corner reach. ~0.55 gives a clean
    /// quarter-ellipse; higher values fatten the curve toward a squircle (and,
    /// pushed too far, into a lumpy bulge).
    var smoothness: CGFloat = 0.55

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(
                AnimatablePair(topRadius, topSpread),
                AnimatablePair(bottomRadius, bottomSpread)
            )
        }
        set {
            topRadius = newValue.first.first
            topSpread = newValue.first.second
            bottomRadius = newValue.second.first
            bottomSpread = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let top = min(topRadius, rect.height / 2)
        let rise = min(bottomRadius, rect.height - top)
        let reach = min(max(topSpread, top), rect.width / 2)
        // Keep the two bottom sweeps from overlapping on a narrow pill.
        let spread = min(bottomSpread, max(0, rect.width / 2 - reach))
        let wall = rect.height - top - rise
        // 0 = no wall: the side is one sigmoid sweep with horizontal tangents at
        // both ends. 1 = walled: outward flare, straight side, bottom sweep.
        // Blending by wall length keeps the outline continuous while the pill
        // grows into the card, instead of popping between constructions.
        let blend = min(1, wall / 24)

        let height = rect.height
        let run = reach + spread
        let handle = run * smoothness

        // Both constructions expressed as the same topology — curve, line,
        // curve — so they can be mixed point-for-point. The sigmoid is split at
        // its midpoint (de Casteljau at t = 0.5) to provide the two curves; its
        // "wall" is the zero-length line at the split.
        //
        // Left-side geometry as offsets from the top-left corner; the right
        // side mirrors it.
        let c1 = mix(
            CGPoint(x: handle / 2, y: 0),
            CGPoint(x: reach * smoothness, y: 0),
            blend
        )
        let c2 = mix(
            CGPoint(x: (handle + run) / 4, y: height / 4),
            CGPoint(x: reach, y: top - top * smoothness),
            blend
        )
        let wallTop = mix(
            CGPoint(x: run / 2, y: height / 2),
            CGPoint(x: reach, y: top),
            blend
        )
        let wallBottom = mix(
            CGPoint(x: run / 2, y: height / 2),
            CGPoint(x: reach, y: height - rise),
            blend
        )
        let c3 = mix(
            CGPoint(x: (3 * run - handle) / 4, y: 3 * height / 4),
            CGPoint(x: reach, y: height - rise + rise * smoothness),
            blend
        )
        let c4 = mix(
            CGPoint(x: run - handle / 2, y: height),
            CGPoint(x: reach + spread - spread * smoothness, y: height),
            blend
        )

        func left(_ p: CGPoint) -> CGPoint {
            CGPoint(x: rect.minX + p.x, y: rect.minY + p.y)
        }
        func right(_ p: CGPoint) -> CGPoint {
            CGPoint(x: rect.maxX - p.x, y: rect.minY + p.y)
        }

        var path = Path()
        // Left side, top to bottom.
        path.move(to: left(.zero))
        path.addCurve(to: left(wallTop), control1: left(c1), control2: left(c2))
        path.addLine(to: left(wallBottom))
        path.addCurve(to: left(CGPoint(x: run, y: height)), control1: left(c3), control2: left(c4))
        // Bottom edge.
        path.addLine(to: right(CGPoint(x: run, y: height)))
        // Right side, bottom to top.
        path.addCurve(to: right(wallBottom), control1: right(c4), control2: right(c3))
        path.addLine(to: right(wallTop))
        path.addCurve(to: right(.zero), control1: right(c2), control2: right(c1))
        path.closeSubpath()
        return path
    }

    private func mix(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
}

// MARK: - Preview playground

/// Interactive canvas for tuning the pill outline: every `NotchShape` parameter
/// plus the pill's dimensions on sliders, over a wallpaper-ish backdrop with a
/// sample title to judge how far the side sweeps cut into the content.
private struct NotchShapePlayground: View {
    @State private var topRadius: CGFloat = 10
    @State private var topSpread: CGFloat = 24
    @State private var bottomRadius: CGFloat = 38
    @State private var bottomSpread: CGFloat = 34
    @State private var smoothness: CGFloat = 0.55
    @State private var width: CGFloat = 470
    @State private var height: CGFloat = 38
    @State private var textPadding: CGFloat = 38

    var body: some View {
        VStack(spacing: 20) {
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [Color(red: 0.45, green: 0.35, blue: 0.55), Color(red: 0.25, green: 0.45, blue: 0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                NotchShape(
                    topRadius: topRadius,
                    topSpread: topSpread,
                    bottomRadius: bottomRadius,
                    bottomSpread: bottomSpread,
                    smoothness: smoothness
                )
                .fill(.black)
                .overlay(alignment: .center) {
                    Text(verbatim: "猛独が襲う (feat. 初音ミク) — 一二三")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                        .padding(.horizontal, textPadding)
                }
                .frame(width: width, height: height)
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Grid(alignment: .leading, verticalSpacing: 6) {
                slider("topRadius", $topRadius, 0...40)
                slider("topSpread", $topSpread, 0...80)
                slider("bottomRadius", $bottomRadius, 0...60)
                slider("bottomSpread", $bottomSpread, 0...100)
                slider("smoothness", $smoothness, 0...1)
                slider("width", $width, 200...600)
                slider("height", $height, 24...140)
                slider("textPadding", $textPadding, 0...80)
            }
            .font(.system(size: 11))
        }
        .padding(20)
        .frame(width: 620)
    }

    private func slider(_ label: String, _ value: Binding<CGFloat>, _ range: ClosedRange<CGFloat>) -> some View {
        GridRow {
            Text(label)
            Slider(value: value, in: range)
                .frame(width: 380)
            Text(String(format: "%.2f", value.wrappedValue))
                .monospacedDigit()
                .gridColumnAlignment(.trailing)
        }
    }
}

#Preview("Notch shape playground") {
    NotchShapePlayground()
}
