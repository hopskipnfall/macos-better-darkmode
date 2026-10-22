import Foundation

public enum ConfigError: Error, Equatable {
    case invalid(String)
}

public struct LuxConfig: Codable, Equatable {
    public var weight = 3.0
    /// Reading (after `scale`) at or above which the room counts as fully bright.
    public var brightLux = 150.0
    /// Reading (after `scale`) at or below which the room counts as fully dark.
    public var darkLux = 5.0
    /// Multiplier from raw sensor units to the lux scale used above.
    public var scale = 1.0

    public init() {}
    enum CodingKeys: String, CodingKey { case weight, brightLux, darkLux, scale }
    public init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        weight = try c.decodeIfPresent(Double.self, forKey: .weight) ?? weight
        brightLux = try c.decodeIfPresent(Double.self, forKey: .brightLux) ?? brightLux
        darkLux = try c.decodeIfPresent(Double.self, forKey: .darkLux) ?? darkLux
        scale = try c.decodeIfPresent(Double.self, forKey: .scale) ?? scale
    }
}

public struct SunConfig: Codable, Equatable {
    public var weight = 2.0
    /// Effective sun elevation (degrees) at or above which it counts as fully bright.
    public var brightElevation = 10.0
    /// Effective sun elevation (degrees) at or below which it counts as fully dark.
    public var darkElevation = -6.0
    /// Degrees of elevation subtracted at 100% cloud cover (scaled linearly).
    public var cloudPenaltyDegrees = 8.0
    /// When the sun heuristic's darkness reaches this value (0...1), it's night outside and the
    /// result is forced dark regardless of the room sensor. Set above 1 to disable.
    public var nightOverrideDarkness = 0.9

    public init() {}
    enum CodingKeys: String, CodingKey {
        case weight, brightElevation, darkElevation, cloudPenaltyDegrees, nightOverrideDarkness
    }
    public init(from decoder: Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        weight = try c.decodeIfPresent(Double.self, forKey: .weight) ?? weight
        brightElevation = try c.decodeIfPresent(Double.self, forKey: .brightElevation) ?? brightElevation
        darkElevation = try c.decodeIfPresent(Double.self, forKey: .darkElevation) ?? darkElevation
        cloudPenaltyDegrees = try c.decodeIfPresent(Double.self, forKey: .cloudPenaltyDegrees) ?? cloudPenaltyDegrees
        nightOverrideDarkness = try c.decodeIfPresent(Double.self, forKey: .nightOverrideDarkness) ?? nightOverrideDarkness
    }
}

public struct Config: Codable, Equatable {
    public var latitude: Double
    public var longitude: Double
    public var darkThreshold = 0.6
    public var lightThreshold = 0.4
    public var minDwellSeconds = 600.0
    public var lux = LuxConfig()
    public var sun = SunConfig()

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    enum CodingKeys: String, CodingKey {
        case latitude, longitude, darkThreshold, lightThreshold, minDwellSeconds, lux, sun
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            latitude: try c.decode(Double.self, forKey: .latitude),
            longitude: try c.decode(Double.self, forKey: .longitude)
        )
        darkThreshold = try c.decodeIfPresent(Double.self, forKey: .darkThreshold) ?? darkThreshold
        lightThreshold = try c.decodeIfPresent(Double.self, forKey: .lightThreshold) ?? lightThreshold
        minDwellSeconds = try c.decodeIfPresent(Double.self, forKey: .minDwellSeconds) ?? minDwellSeconds
        lux = try c.decodeIfPresent(LuxConfig.self, forKey: .lux) ?? lux
        sun = try c.decodeIfPresent(SunConfig.self, forKey: .sun) ?? sun
    }

    public static let example = Config(latitude: 0, longitude: 0)

    public static func parse(_ data: Data) throws -> Config {
        let config = try JSONDecoder().decode(Config.self, from: data)
        try config.validate()
        return config
    }

    func validate() throws {
        guard (-90...90).contains(latitude) else { throw ConfigError.invalid("latitude must be within -90...90") }
        guard (-180...180).contains(longitude) else { throw ConfigError.invalid("longitude must be within -180...180") }
        guard lightThreshold < darkThreshold else {
            throw ConfigError.invalid("lightThreshold must be less than darkThreshold")
        }
        guard minDwellSeconds >= 0 else { throw ConfigError.invalid("minDwellSeconds must be >= 0") }
    }
}
