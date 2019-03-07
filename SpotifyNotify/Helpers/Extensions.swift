//
//  Extensions.swift
//  SpotifyNotify
//
//  Created by 先生 on 22/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Cocoa

extension NSButton {
	var isSelected: Bool {
		get { return state.rawValue == 1 }
		set { state = NSControl.StateValue(rawValue: newValue ? 1 : 0) }
	}
}

extension String {
	var url: URL? { return URL(string: self) }
    var cfString: CFString { return self as CFString }
	var withLeadingZeroes: String {
		guard let int = Int(self) else { return self }
		return String(format: "%02d", int)
	}
}

extension URL {
    var image: NSImage? {
		guard let data = try? Data(contentsOf: self) else { return nil }
		return NSImage(data: data)
    }
	
	func asyncImage(result: @escaping (NSImage?) -> Void) {
		URLSession.shared.dataTask(with: self) { (data, res, err) in
			guard let data = data, let image = NSImage(data: data) else {
				result(nil)
				return
			}
			result(image)
		}.resume()
		
	}
}

extension Data {
	var image: NSImage? {
		return NSImage(data: self)
	}
}

// private apple apis
extension NSUserNotification {
    
    enum IdentityImageStyle: Int {
        case normal = 0
        case rounded = 2
    }
    
    var identityImage: NSImage? {
        get { return value(forKey: "_identityImage") as? NSImage }
        set { setValue(newValue, forKey: "_identityImage") }
    }
    
    var identityImageStyle: IdentityImageStyle {
        get {
            guard
                let value = value(forKey: "_identityImageStyle") as? Int,
                let style = IdentityImageStyle(rawValue: value) else {
                    return .normal
            }
            
            return style
        }
        set {
            setValue(newValue.rawValue, forKey: "_identityImageStyle")
        }
    }
}

extension NSImage {
    /// Save an NSImage to a temporary directory
    ///
    /// - Parameter name: The file name, to use
    /// - Returns: A URL if saving is successful, or nil if there was an error
    func saveToTemporaryDirectory(withName name: String) -> URL? {
        guard let data = tiffRepresentation else { return nil }

        let fileManager = FileManager.default
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        let bundleURL = tempURL.appendingPathComponent(AppConstants.bundleIdentifier, isDirectory: true)

        do {
            try fileManager.createDirectory(at: bundleURL, withIntermediateDirectories: true)
            let fileURL = bundleURL.appendingPathComponent(name + ".png")

            try NSBitmapImageRep(data: data)?
                .representation(using: .png, properties: [:])?
                .write(to: fileURL)

            return fileURL
        } catch {
            print("Error: " + error.localizedDescription)
        }

        return nil
    }
}

extension NSImage {
    /// Apply a circular mask to the image
    func applyCircularMask() -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high
        let frame = NSRect(origin: .zero, size: size)
        NSBezierPath(ovalIn: frame).addClip()
        draw(at: .zero, from: frame, operation: .sourceOver, fraction: 1)

        image.unlockFocus()
        return image
    }
}
