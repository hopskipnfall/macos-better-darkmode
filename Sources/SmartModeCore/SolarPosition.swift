import Foundation

/// Sun elevation in degrees above the horizon, ignoring atmospheric refraction.
/// Uses the Astronomical Almanac low-precision solar coordinates (accurate to ~0.1°).
public func solarElevation(at date: Date, latitude: Double, longitude: Double) -> Double {
    func rad(_ d: Double) -> Double { d * .pi / 180 }
    func wrap360(_ d: Double) -> Double {
        let r = d.truncatingRemainder(dividingBy: 360)
        return r < 0 ? r + 360 : r
    }

    let julianDay = date.timeIntervalSince1970 / 86400 + 2440587.5
    let n = julianDay - 2451545.0                       // days since J2000.0

    let meanLongitude = wrap360(280.460 + 0.9856474 * n)
    let meanAnomaly = rad(wrap360(357.528 + 0.9856003 * n))
    let eclipticLongitude = rad(meanLongitude + 1.915 * sin(meanAnomaly) + 0.020 * sin(2 * meanAnomaly))
    let obliquity = rad(23.439 - 0.0000004 * n)

    let declination = asin(sin(obliquity) * sin(eclipticLongitude))
    let rightAscension = atan2(cos(obliquity) * sin(eclipticLongitude), cos(eclipticLongitude))

    let gmst = wrap360(280.46061837 + 360.98564736629 * n)
    let hourAngle = rad(gmst + longitude) - rightAscension

    let lat = rad(latitude)
    let sinElevation = sin(lat) * sin(declination) + cos(lat) * cos(declination) * cos(hourAngle)
    return asin(min(1, max(-1, sinElevation))) * 180 / .pi
}
