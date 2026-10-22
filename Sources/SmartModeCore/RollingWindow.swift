import Foundation

/// Keeps recent samples and reports their median, which shrugs off brief shadows and flicker.
public struct RollingWindow {
    private let duration: TimeInterval
    private var samples: [(date: Date, value: Double)] = []

    public init(duration: TimeInterval) {
        self.duration = duration
    }

    public mutating func add(_ value: Double, at date: Date) {
        samples.append((date, value))
        samples.removeAll { date.timeIntervalSince($0.date) > duration }
    }

    public func median(at date: Date) -> Double? {
        let recent = samples.filter { date.timeIntervalSince($0.date) <= duration }.map(\.value).sorted()
        guard !recent.isEmpty else { return nil }
        let mid = recent.count / 2
        return recent.count % 2 == 1 ? recent[mid] : (recent[mid - 1] + recent[mid]) / 2
    }
}
