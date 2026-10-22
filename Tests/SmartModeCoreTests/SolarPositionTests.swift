import Foundation
import Testing
@testable import SmartModeCore

struct SolarPositionTests {
    private func date(_ iso: String) -> Date { ISO8601DateFormatter().date(from: iso)! }

    @Test func sunNearZenithAtEquatorNearEquinoxNoon() {
        // Solar noon at lon 0 is ~12:07 UTC on Mar 20; declination is ~0.
        let e = solarElevation(at: date("2026-03-20T12:07:00Z"), latitude: 0, longitude: 0)
        #expect(e > 88)
    }

    @Test func sunFarBelowHorizonAtLocalMidnight() {
        let e = solarElevation(at: date("2026-03-20T00:07:00Z"), latitude: 0, longitude: 0)
        #expect(e < -85)
    }

    @Test func summerSolsticeNoonInNewYork() {
        // Solar noon ~16:57:40 UTC. Expected elevation = 90 - 40.71 + 23.44 = 72.73.
        let e = solarElevation(at: date("2026-06-21T16:58:00Z"), latitude: 40.7128, longitude: -74.0060)
        #expect(near(e, 72.73, 0.5))
    }

    @Test func winterSolsticeNoonInNewYorkIsLow() {
        // Solar noon ~16:57 UTC. Expected = 90 - 40.71 - 23.44 = 25.85.
        let e = solarElevation(at: date("2026-12-21T16:57:00Z"), latitude: 40.7128, longitude: -74.0060)
        #expect(near(e, 25.85, 0.5))
    }

    @Test func polarNightIsNegativeAllDay() {
        let e = solarElevation(at: date("2026-12-21T12:00:00Z"), latitude: 78, longitude: 15)
        #expect(e < 0)
    }
}
