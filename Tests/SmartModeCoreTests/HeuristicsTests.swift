import Testing
@testable import SmartModeCore

struct HeuristicsTests {
    @Test func luxIsLogScaled() {
        let c = LuxConfig() // bright 150, dark 5
        #expect(near(luxHeuristic(Readings(lux: 150), c).darkness!, 0))
        #expect(near(luxHeuristic(Readings(lux: 5), c).darkness!, 1))
        // geometric mean of 150 and 5 is the log-scale midpoint
        #expect(near(luxHeuristic(Readings(lux: (150.0 * 5.0).squareRoot()), c).darkness!, 0.5, 1e-6))
    }

    @Test func luxScaleMultipliesRawReading() {
        var c = LuxConfig()
        c.scale = 10
        #expect(near(luxHeuristic(Readings(lux: 15), c).darkness!, 0)) // 15*10 = 150
    }

    @Test func luxZeroIsFullyDarkNotNaN() {
        #expect(near(luxHeuristic(Readings(lux: 0), LuxConfig()).darkness!, 1))
    }

    @Test func luxUnavailableWhenNil() {
        #expect(luxHeuristic(Readings(), LuxConfig()).darkness == nil)
    }

    @Test func sunElevationRamp() {
        let c = SunConfig() // bright 10, dark -6
        #expect(near(sunHeuristic(Readings(sunElevation: 10), c).darkness!, 0))
        #expect(near(sunHeuristic(Readings(sunElevation: -6), c).darkness!, 1))
        #expect(near(sunHeuristic(Readings(sunElevation: 2), c).darkness!, 0.5))
    }

    @Test func cloudCoverLowersEffectiveElevation() {
        let c = SunConfig() // penalty 8° at 100%
        // 10° - 8° = 2° effective -> 0.5
        #expect(near(sunHeuristic(Readings(sunElevation: 10, cloudCoverPercent: 100), c).darkness!, 0.5))
        // half cover -> 4° penalty -> 6° effective -> 0.25
        #expect(near(sunHeuristic(Readings(sunElevation: 10, cloudCoverPercent: 50), c).darkness!, 0.25))
    }

    @Test func missingCloudCoverIsTreatedAsClear() {
        #expect(near(sunHeuristic(Readings(sunElevation: 10), SunConfig()).darkness!, 0))
    }

    @Test func sunUnavailableWhenNil() {
        #expect(sunHeuristic(Readings(), SunConfig()).darkness == nil)
    }
}
