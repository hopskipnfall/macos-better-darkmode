import Foundation

public struct Readings: Equatable {
    public var lux: Double?
    public var sunElevation: Double?
    public var cloudCoverPercent: Double?

    public init(lux: Double? = nil, sunElevation: Double? = nil, cloudCoverPercent: Double? = nil) {
        self.lux = lux
        self.sunElevation = sunElevation
        self.cloudCoverPercent = cloudCoverPercent
    }
}

public struct HeuristicResult: Equatable {
    public let name: String
    /// 0 = fully bright, 1 = fully dark. `nil` means the heuristic has no data.
    public let darkness: Double?
    public let weight: Double
    public let detail: String
}

public func luxHeuristic(_ r: Readings, _ c: LuxConfig) -> HeuristicResult {
    guard let raw = r.lux else {
        return HeuristicResult(name: "lux", darkness: nil, weight: c.weight, detail: "no sensor reading")
    }
    let scaled = max(raw * c.scale, 0.01) // avoid log10(0)
    let darkness = ramp(log10(scaled), bright: log10(c.brightLux), dark: log10(c.darkLux))
    return HeuristicResult(name: "lux", darkness: darkness, weight: c.weight,
                           detail: String(format: "%.1f lux", scaled))
}

public func sunHeuristic(_ r: Readings, _ c: SunConfig) -> HeuristicResult {
    guard let elevation = r.sunElevation else {
        return HeuristicResult(name: "sun", darkness: nil, weight: c.weight, detail: "no position")
    }
    let cloud = min(100, max(0, r.cloudCoverPercent ?? 0))
    let effective = elevation - c.cloudPenaltyDegrees * cloud / 100
    let darkness = ramp(effective, bright: c.brightElevation, dark: c.darkElevation)
    let cloudText = r.cloudCoverPercent.map { String(format: ", %.0f%% cloud", $0) } ?? ", cloud n/a"
    return HeuristicResult(name: "sun", darkness: darkness, weight: c.weight,
                           detail: String(format: "%.1f° elevation%@", elevation, cloudText))
}
