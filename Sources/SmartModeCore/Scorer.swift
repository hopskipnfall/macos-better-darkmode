public struct ScoreBreakdown: Equatable {
    public let results: [HeuristicResult]
    /// Final darkness in 0...1, or `nil` if no heuristic contributed.
    public let score: Double?
    /// Set when a rule (rather than the weighted blend) decided the score.
    public let overrideReason: String?
}

public func computeScore(_ r: Readings, config: Config) -> ScoreBreakdown {
    let lux = luxHeuristic(r, config.lux)
    let sun = sunHeuristic(r, config.sun)
    let results = [lux, sun]

    // It's dark outside: always dark, whatever the room sensor says.
    if config.sun.weight > 0, let sunDarkness = sun.darkness, sunDarkness >= config.sun.nightOverrideDarkness {
        return ScoreBreakdown(results: results, score: 1,
                              overrideReason: "dark outside (sun darkness \(String(format: "%.2f", sunDarkness)) ≥ \(config.sun.nightOverrideDarkness))")
    }

    var weightedSum = 0.0
    var totalWeight = 0.0
    for result in results {
        guard let d = result.darkness, result.weight > 0 else { continue }
        weightedSum += d * result.weight
        totalWeight += result.weight
    }
    return ScoreBreakdown(results: results, score: totalWeight > 0 ? weightedSum / totalWeight : nil,
                          overrideReason: nil)
}
