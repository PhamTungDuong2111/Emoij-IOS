import SwiftUI

@main
struct EmojiMaskApp: App {
    @StateObject private var localization = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(localization)
                .preferredColorScheme(.dark)
        }
    }
}
