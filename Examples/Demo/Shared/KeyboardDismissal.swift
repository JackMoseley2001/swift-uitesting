import UITestingCore

/// How the profile form's scroll view dismisses the keyboard when it is dragged.
///
/// A UI test passes one as a launch payload to check that the keyboard can be put away
/// in each of the ways an app can be set up. Without one, the form uses ``immediately``.
enum KeyboardDismissal: String, CaseIterable, LaunchPayload {
    case automatic
    case immediately
    case interactively
    case never
}
