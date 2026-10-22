import Foundation
import SwiftUI
import SmartModeCore

@MainActor
final class AppModel: ObservableObject {
    @Published var lines: [String] = ["starting…"]
    @Published var configError: String?
    @Published var paused = false {
        didSet { controller.paused = paused }
    }

    static let configURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/smart-mode/config.json")

    private var controller = ModeController(config: .example)
    private var configModified: Date?
    private let sensor = SensorProvider()
    private let weather = WeatherProvider()
    private var timer: Timer?
    private var lastApplyError: String?

    init() {
        writeExampleConfigIfMissing()
        tick()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func openConfig() {
        NSWorkspace.shared.open(Self.configURL)
    }

    private func writeExampleConfigIfMissing() {
        let url = Self.configURL
        guard !FileManager.default.fileExists(atPath: url.path) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(Config.example) { try? data.write(to: url) }
    }

    private func reloadConfigIfChanged() {
        let url = Self.configURL
        let modified = (try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate]) as? Date
        guard modified != configModified else { return }
        configModified = modified
        do {
            controller.config = try Config.parse(Data(contentsOf: url))
            configError = nil
        } catch {
            configError = "Config error (using last good): \(error)"
        }
    }

    private func tick() {
        let now = Date()
        reloadConfigIfChanged()
        let config = controller.config

        weather.refreshIfNeeded(latitude: config.latitude, longitude: config.longitude, now: now)
        let readings = Readings(
            lux: sensor.read(now: now),
            sunElevation: solarElevation(at: now, latitude: config.latitude, longitude: config.longitude),
            cloudCoverPercent: weather.cloudCover(now: now)
        )
        let breakdown = computeScore(readings, config: config)

        let system = Applier.current()
        let action = controller.evaluate(score: breakdown.score, system: system, now: now)
        let actionLine: String
        switch action {
        case .hold(let why):
            actionLine = "holding: \(why)"
        case .set(let appearance, let why):
            do {
                try Applier.set(appearance)
                lastApplyError = nil
                actionLine = "switched to \(appearance.rawValue) (\(why))"
            } catch {
                lastApplyError = error.localizedDescription
                actionLine = "switch failed"
            }
        }

        var out: [String] = []
        out.append("Now: \(system.rawValue) · \(actionLine)")
        out.append(breakdown.score.map {
            String(format: "Score: %.2f  (dark > %.2f, light < %.2f)", $0, config.darkThreshold, config.lightThreshold)
        } ?? "Score: n/a")
        if let reason = breakdown.overrideReason { out.append("Night override: \(reason)") }
        for r in breakdown.results {
            let d = r.darkness.map { String(format: "%.2f", $0) } ?? "n/a"
            out.append("  \(r.name): \(d)  w=\(r.weight)  \(r.detail)")
        }
        if controller.overridden { out.append("Manual override active") }
        if let lastApplyError { out.append("Apply error: \(lastApplyError)") }
        if config.latitude == 0 && config.longitude == 0 { out.append("Set your latitude/longitude in the config") }
        lines = out
    }
}
