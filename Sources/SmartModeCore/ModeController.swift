import Foundation

public enum Action: Equatable {
    case hold(String)
    case set(Appearance, String)

    public var target: Appearance? {
        if case .set(let a, _) = self { return a }
        return nil
    }
}

public struct ModeController {
    public var config: Config
    public var paused = false
    /// What the score alone says the mode should be (hysteresis applied), independent of overrides.
    public private(set) var autoMode: Appearance?
    public private(set) var overridden = false

    private var expected: Appearance?   // what we believe the system appearance currently is
    private var lastSwitch: Date?

    public init(config: Config) {
        self.config = config
    }

    public mutating func evaluate(score: Double?, system: Appearance, now: Date) -> Action {
        if let expected, expected != system { overridden = true }
        expected = system

        guard let score else { return .hold("no signals") }

        let previousAuto = autoMode
        switch autoMode {
        case nil:
            autoMode = score >= (config.darkThreshold + config.lightThreshold) / 2 ? .dark : .light
        case .light? where score > config.darkThreshold:
            autoMode = .dark
        case .dark? where score < config.lightThreshold:
            autoMode = .light
        default:
            break
        }
        guard let auto = autoMode else { return .hold("no signals") }

        if overridden, (previousAuto != nil && previousAuto != auto) || system == auto {
            overridden = false
        }

        if paused { return .hold("paused") }
        if overridden { return .hold("manual override until auto decision changes") }
        if system == auto { return .hold("in sync (\(auto.rawValue))") }

        if let lastSwitch, now.timeIntervalSince(lastSwitch) < config.minDwellSeconds {
            return .hold("waiting out minimum dwell")
        }
        lastSwitch = now
        expected = auto
        return .set(auto, String(format: "score %.2f", score))
    }
}
