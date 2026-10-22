import Foundation

private struct OpenMeteoResponse: Decodable {
    struct Current: Decodable { let cloud_cover: Double }
    let current: Current
}

/// Extracts cloud cover (percent) from an Open-Meteo `forecast?current=cloud_cover` response.
public func parseCloudCover(_ data: Data) throws -> Double {
    try JSONDecoder().decode(OpenMeteoResponse.self, from: data).current.cloud_cover
}
