import Foundation

extension Int {
    var minutesSeconds: (minutes: Int, seconds: Int) {
        (self / 60, self % 60)
    }
}
