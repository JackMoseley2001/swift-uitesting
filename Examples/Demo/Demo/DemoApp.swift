import SwiftUI
import UITestingCore

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            ExampleList(traits: .current)
                .uiTestAnimationsDisabled()
                .onOpenURL { OpenedLinks.shared.latest = $0 }
        }
    }
}
