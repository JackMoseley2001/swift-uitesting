import UITestingCore

/// A screen of the demo app, each of which shows one thing that UI tests exercise.
///
/// A UI test passes an example as a launch payload to open the app on that screen,
/// so that it does not have to go through the list of examples first.
enum Example: String, CaseIterable, Identifiable, LaunchPayload {
    case account
    case message
    case profileForm
    case fruitList
    case numberList
    case launchSettings
    case controls

    var id: Self { self }

    var title: String {
        switch self {
        case .account: "Account"
        case .message: "Message"
        case .profileForm: "Profile form"
        case .fruitList: "Fruit list"
        case .numberList: "Number list"
        case .launchSettings: "Launch settings"
        case .controls: "Controls"
        }
    }
}
