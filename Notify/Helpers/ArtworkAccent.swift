import AppKit
import CoreImage
import SwiftUI

@MainActor
enum ArtworkAccent {
    private static let context = CIContext(options: [.workingColorSpace: NSNull()])

    /// Average color of the artwork, pushed towards a vivid, glow-friendly tone.
    static func color(from image: NSImage?) -> Color? {
        guard let image,
              let tiff = image.tiffRepresentation,
              let ciImage = CIImage(data: tiff) else { return nil }

        let extent = ciImage.extent
        guard !extent.isEmpty, extent.isFinite else { return nil }

        guard let filter = CIFilter(name: "CIAreaAverage") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
        guard let output = filter.outputImage else { return nil }

        var pixel = [UInt8](repeating: 0, count: 4)
        context.render(
            output,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        let average = NSColor(
            red: CGFloat(pixel[0]) / 255,
            green: CGFloat(pixel[1]) / 255,
            blue: CGFloat(pixel[2]) / 255,
            alpha: 1
        )

        guard let hsb = average.usingColorSpace(.deviceRGB) else { return nil }
        let saturation = hsb.saturationComponent < 0.1 ? hsb.saturationComponent : max(hsb.saturationComponent, 0.6)
        return Color(
            hue: hsb.hueComponent,
            saturation: saturation,
            brightness: max(hsb.brightnessComponent, 0.8)
        )
    }
}

private extension CGRect {
    var isFinite: Bool {
        !isInfinite && !isNull && width.isFinite && height.isFinite
    }
}
