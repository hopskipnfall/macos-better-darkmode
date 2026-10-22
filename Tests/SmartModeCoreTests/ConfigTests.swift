import Foundation
import Testing
@testable import SmartModeCore

struct ConfigTests {
    private func data(_ s: String) -> Data { s.data(using: .utf8)! }

    @Test func minimalConfigGetsDefaults() throws {
        let c = try Config.parse(data(#"{"latitude": 40.7, "longitude": -74.0}"#))
        #expect(c.latitude == 40.7)
        #expect(c.longitude == -74.0)
        #expect(c.darkThreshold == 0.6)
        #expect(c.lightThreshold == 0.4)
        #expect(c.minDwellSeconds == 600)
        #expect(c.lux.weight == 3)
        #expect(c.sun.darkElevation == -6)
        #expect(c.sun.nightOverrideDarkness == 0.9)
    }

    @Test func nightOverrideThresholdIsConfigurable() throws {
        let c = try Config.parse(data(#"{"latitude": 0, "longitude": 0, "sun": {"nightOverrideDarkness": 0.5}}"#))
        #expect(c.sun.nightOverrideDarkness == 0.5)
        #expect(c.sun.weight == 2) // untouched default
    }

    @Test func partialOverrideOfNestedSection() throws {
        let c = try Config.parse(data(#"{"latitude": 0, "longitude": 0, "lux": {"weight": 0}}"#))
        #expect(c.lux.weight == 0)
        #expect(c.lux.darkLux == 5) // untouched default
    }

    @Test func rejectsInvertedThresholds() {
        #expect(throws: (any Error).self) {
            try Config.parse(data(#"{"latitude": 0, "longitude": 0, "darkThreshold": 0.3, "lightThreshold": 0.7}"#))
        }
    }

    @Test func rejectsOutOfRangeLatitude() {
        #expect(throws: (any Error).self) {
            try Config.parse(data(#"{"latitude": 123, "longitude": 0}"#))
        }
    }

    @Test func rejectsMalformedJSON() {
        #expect(throws: (any Error).self) { try Config.parse(data("{nope")) }
    }

    @Test func exampleRoundTrips() throws {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        let encoded = try enc.encode(Config.example)
        #expect(try Config.parse(encoded) == Config.example)
    }
}
