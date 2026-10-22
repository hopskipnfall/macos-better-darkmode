import SwiftUI

@main
struct SmartModeApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra("Smart Mode", systemImage: "circle.lefthalf.filled") {
            MenuView(model: model)
        }
    }
}
