import UITestingCore

struct AuthState: LaunchPayload, Equatable {
    var isLoggedIn: Bool
    var userID: String?
}

struct FeatureFlags: LaunchPayload, Equatable {
    static let launchKey = "flags"

    var enabled: [String]
}

enum Settings {
    struct Theme: LaunchPayload, Equatable {
        var name: String
    }
}
