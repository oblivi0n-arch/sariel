import Foundation

extension Date {
    var dayKey: String {
        Self.formatter.string(from: self)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
