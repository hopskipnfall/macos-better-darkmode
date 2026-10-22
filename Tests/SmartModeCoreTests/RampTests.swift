import Testing
@testable import SmartModeCore

struct RampTests {
    @Test func endpointsAndMidpoint() {
        #expect(near(ramp(200, bright: 200, dark: 5), 0))
        #expect(near(ramp(5, bright: 200, dark: 5), 1))
        #expect(near(ramp(10, bright: 20, dark: 0), 0.5))
    }

    @Test func clampsOutsideRange() {
        #expect(near(ramp(1000, bright: 200, dark: 5), 0))
        #expect(near(ramp(-3, bright: 200, dark: 5), 1))
    }

    @Test func degenerateRangeIsAStep() {
        #expect(ramp(4, bright: 5, dark: 5) == 1)
        #expect(ramp(6, bright: 5, dark: 5) == 0)
    }
}
