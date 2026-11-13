import SwiftUI

@main
struct PaperdownApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }

        Settings {
            SettingsView()
        }
    }
}
