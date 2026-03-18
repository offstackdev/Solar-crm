import Foundation

extension Array where Element == Lead {
    func groupedByStatus() -> [LeadStatus: [Lead]] {
        Dictionary(grouping: self, by: \.currentStatus)
    }
}
