import Foundation
import Testing
@testable import SmartModeCore

struct RollingWindowTests {
    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    @Test func emptyHasNoMedian() {
        #expect(RollingWindow(duration: 60).median(at: t0) == nil)
    }

    @Test func medianOfOddAndEvenCounts() {
        var w = RollingWindow(duration: 60)
        w.add(10, at: t0); w.add(1000, at: t0 + 1); w.add(20, at: t0 + 2)
        #expect(w.median(at: t0 + 3) == 20)   // spike rejected
        w.add(30, at: t0 + 4)
        #expect(w.median(at: t0 + 5) == 25)   // mean of 20 and 30
    }

    @Test func oldSamplesAreDropped() {
        var w = RollingWindow(duration: 60)
        w.add(500, at: t0)
        w.add(10, at: t0 + 100)
        #expect(w.median(at: t0 + 101) == 10)
    }

    @Test func allSamplesExpiredGivesNil() {
        var w = RollingWindow(duration: 60)
        w.add(5, at: t0)
        #expect(w.median(at: t0 + 120) == nil)
    }
}
