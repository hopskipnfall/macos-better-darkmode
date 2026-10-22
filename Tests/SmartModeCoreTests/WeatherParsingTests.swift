import Foundation
import Testing
@testable import SmartModeCore

struct WeatherParsingTests {
    @Test func parsesOpenMeteoResponse() throws {
        let json = """
        {"latitude":40.7,"longitude":-74.0,"current_units":{"cloud_cover":"%"},
         "current":{"time":"2026-10-08T12:00","interval":900,"cloud_cover":72}}
        """.data(using: .utf8)!
        #expect(try parseCloudCover(json) == 72)
    }

    @Test func throwsWhenFieldMissing() {
        #expect(throws: (any Error).self) {
            try parseCloudCover(#"{"current":{}}"#.data(using: .utf8)!)
        }
    }
}
