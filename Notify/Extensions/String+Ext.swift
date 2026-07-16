import Foundation
import SwiftUI

extension String {
    func repeated(_ times: Int) -> String {
        return String(repeating: self, count: times)
    }
    
    var asURL: URL? {
        URL(string: self)
    }
}
