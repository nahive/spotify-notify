import SwiftUI

/// The MacBook notch outline: top corners flare outward, bottom corners round in.
/// Corners are drawn with continuous-curvature cubic Béziers so the transitions
/// read as a smooth wave rather than hard circular arcs.
struct NotchShape: Shape {
    var topRadius: CGFloat
    var bottomRadius: CGFloat
    /// Handle length as a fraction of the radius. 0.55 ≈ a circular arc; higher
    /// values push the corners toward a softer squircle / wave.
    var smoothness: CGFloat = 0.92

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topRadius, bottomRadius) }
        set {
            topRadius = newValue.first
            bottomRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let top = min(topRadius, rect.height / 2)
        let bottom = min(bottomRadius, rect.height - top)
        let ts = top * smoothness
        let bs = bottom * smoothness

        // Top-left outward flare.
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.minX + top, y: rect.minY + top),
            control1: CGPoint(x: rect.minX + ts, y: rect.minY),
            control2: CGPoint(x: rect.minX + top, y: rect.minY + top - ts)
        )
        // Left side.
        path.addLine(to: CGPoint(x: rect.minX + top, y: rect.maxY - bottom))
        // Bottom-left round.
        path.addCurve(
            to: CGPoint(x: rect.minX + top + bottom, y: rect.maxY),
            control1: CGPoint(x: rect.minX + top, y: rect.maxY - bottom + bs),
            control2: CGPoint(x: rect.minX + top + bottom - bs, y: rect.maxY)
        )
        // Bottom edge.
        path.addLine(to: CGPoint(x: rect.maxX - top - bottom, y: rect.maxY))
        // Bottom-right round.
        path.addCurve(
            to: CGPoint(x: rect.maxX - top, y: rect.maxY - bottom),
            control1: CGPoint(x: rect.maxX - top - bottom + bs, y: rect.maxY),
            control2: CGPoint(x: rect.maxX - top, y: rect.maxY - bottom + bs)
        )
        // Right side.
        path.addLine(to: CGPoint(x: rect.maxX - top, y: rect.minY + top))
        // Top-right outward flare.
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control1: CGPoint(x: rect.maxX - top, y: rect.minY + top - ts),
            control2: CGPoint(x: rect.maxX - ts, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}
