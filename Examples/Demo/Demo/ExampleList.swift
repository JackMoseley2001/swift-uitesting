import SwiftUI
import UITestingCore

/// The root of the app: a list of examples, each of which opens on its own screen.
///
/// When a UI test launches the app with an ``Example`` as a launch payload, the app
/// opens on that example's screen.
struct ExampleList: View {
    @State private var path: [Example]

    init(traits: LaunchTraits) {
        _path = State(initialValue: traits[Example.self].map { [$0] } ?? [])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List(Example.allCases) { example in
                NavigationLink(example.title, value: example)
                    .accessibilityIdentifier(ExampleID.row(example))
            }
            .navigationTitle("Examples")
            .navigationDestination(for: Example.self) { example in
                ExampleScreen(example: example)
                    .navigationTitle(example.title)
                    .navigationBarTitleDisplayMode(.inline)
                    // A pushed screen is a hierarchy of its own, so it asks for itself.
                    .uiTestAnimationsDisabled()
            }
        }
    }
}

/// The screen for one example.
private struct ExampleScreen: View {
    let example: Example

    var body: some View {
        switch example {
        case .account: AccountView(traits: .current)
        case .message: MessageView()
        case .profileForm: ProfileForm()
        case .fruitList: FruitList()
        case .numberList: NumberList()
        case .launchSettings: LaunchSettingsView()
        case .controls: ControlsView()
        case .animation: AnimationView()
        }
    }
}
