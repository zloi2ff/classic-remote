import SwiftUI

@main
struct ClassicRemoteWatchApp: App {

    init() {
        WatchSessionReceiver.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
