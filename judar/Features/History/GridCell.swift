import Foundation

struct GridCell: Identifiable {
    let day: Date
    let slot: Int  // 0..<48  (slot = hour*2 + (min>=30 ? 1 : 0))
    var id: String { "\(day.timeIntervalSince1970)_\(slot)" }
}
