import SwiftUI
import UITestingCore

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(traits: .current)
        }
    }
}
