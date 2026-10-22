import SwiftUI

struct MenuView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ForEach(Array(model.lines.enumerated()), id: \.offset) { _, line in
            Text(line)
        }
        if let error = model.configError {
            Divider()
            Text(error)
        }
        Divider()
        Button(model.paused ? "Resume auto switching" : "Pause auto switching") {
            model.paused.toggle()
        }
        Button("Open config…") { model.openConfig() }
        Button("Quit") { NSApplication.shared.terminate(nil) }
    }
}
