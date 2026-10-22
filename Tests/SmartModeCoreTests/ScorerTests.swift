import Testing
@testable import SmartModeCore

struct ScorerTests {
    private let config = Config(latitude: 0, longitude: 0) // lux weight 3, sun weight 2

    @Test func weightedAverage() {
        // lux 5 -> darkness 1 (w3); sun 10° -> darkness 0 (w2): (3*1 + 2*0)/5 = 0.6
        let b = computeScore(Readings(lux: 5, sunElevation: 10), config: config)
        #expect(near(b.score!, 0.6))
        #expect(b.results.count == 2)
    }

    @Test func unavailableHeuristicDropsOutAndWeightsRenormalize() {
        let b = computeScore(Readings(sunElevation: -6), config: config)
        #expect(near(b.score!, 1))
    }

    @Test func zeroWeightDisablesHeuristic() {
        var c = config
        c.lux.weight = 0
        let b = computeScore(Readings(lux: 5, sunElevation: 10), config: c)
        #expect(near(b.score!, 0)) // only sun counts
    }

    @Test func noAvailableSignalsGivesNilScore() {
        #expect(computeScore(Readings(), config: config).score == nil)
    }

    // MARK: night override

    @Test func darkOutsideForcesDarkEvenInABrightRoom() {
        // Sun 24° below the horizon, office lit at 348 lux.
        let b = computeScore(Readings(lux: 348, sunElevation: -24), config: config)
        #expect(near(b.score!, 1))
        #expect(b.overrideReason != nil)
    }

    @Test func overrideAppliesWithoutAnySensorReading() {
        let b = computeScore(Readings(sunElevation: -24), config: config)
        #expect(near(b.score!, 1))
        #expect(b.overrideReason != nil)
    }

    @Test func daylightLeavesDecisionToTheRoomSensor() {
        var c = config
        c.lux.weight = 6
        let darkRoom = computeScore(Readings(lux: 1.4, sunElevation: 15), config: c)
        #expect(darkRoom.overrideReason == nil)
        #expect(near(darkRoom.score!, 0.75))   // 6*1 / (6+2)
        let brightRoom = computeScore(Readings(lux: 348, sunElevation: 15), config: c)
        #expect(near(brightRoom.score!, 0))
    }

    @Test func twilightBelowTheGateIsStillBlended() {
        // Sun at 2° -> darkness 0.5, under the 0.9 gate: no override.
        let b = computeScore(Readings(lux: 348, sunElevation: 2), config: config)
        #expect(b.overrideReason == nil)
        #expect(near(b.score!, (3 * 0 + 2 * 0.5) / 5))
    }

    @Test func overrideCanBeDisabledWithAThresholdAboveOne() {
        var c = config
        c.sun.nightOverrideDarkness = 1.5
        let b = computeScore(Readings(lux: 348, sunElevation: -24), config: c)
        #expect(b.overrideReason == nil)
        #expect(near(b.score!, 0.4))           // (3*0 + 2*1)/5
    }

    @Test func overrideIsOffWhenSunHeuristicIsDisabled() {
        var c = config
        c.sun.weight = 0
        let b = computeScore(Readings(lux: 348, sunElevation: -24), config: c)
        #expect(b.overrideReason == nil)
        #expect(near(b.score!, 0))             // lux only
    }

    @Test func cloudCoverCanTriggerTheOverrideAtDusk() {
        // Sun at -2° with 100% cloud -> effective -10° -> darkness 1.
        let b = computeScore(Readings(lux: 348, sunElevation: -2, cloudCoverPercent: 100), config: config)
        #expect(b.overrideReason != nil)
    }
}
