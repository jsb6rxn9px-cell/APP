import SwiftUI

@main
struct GaitBACApp: App {
    @StateObject var app = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .background { app.recorder.pause() }
                }
        }
    }
}

