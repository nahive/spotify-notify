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
