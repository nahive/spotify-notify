//
//  String+Ext.swift
//  Notify
//
//  Created by Szymon Maślanka on 2023/06/11.
//  Copyright © 2023 Szymon Maślanka. All rights reserved.
//

import Foundation
import SwiftUI

extension String {
    var repeated: String {
        return String(repeating: self, count: count)
    }
    
    func repeated(_ times: Int) -> String {
        return String(repeating: self, count: times)
    }
    
    var withLeadingZeroes: String {
        if self.count == 1 {
            return "0" + self
        }
        return self
    }
    
    var asURL: URL? {
        URL(string: self)
    }
}

extension Int {
    var minutesSeconds: (minutes: Int, seconds: Int) {
        (self / 60, self % 60)
    }
}

// MARK: - Custom Colors
extension Color {
    static let appGreen = Color(red: 0.275, green: 0.898, blue: 0.545) // #46e58b
    static let appAccent = appGreen
}
