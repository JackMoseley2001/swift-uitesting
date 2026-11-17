# Configuring the launch

Choose the arguments, environment, data and settings that the app is launched with.

## Overview

A UI test runs in a separate process from the app, so what it wants of the app has to
be said before the app starts. These traits each add something to the launch. They
are applied in the order they are written, the suite's before the test's, so a test
can override its suite.

## Sending typed data

`.launch(_:)` sends a `LaunchPayload`, which is a `Codable` type that the app and the
UI test target both compile. The app reads it back with `LaunchTraits.current`, from
UITestingCore.

```swift
@UITestSuite(traits: .launch(AuthState(isLoggedIn: true, name: "Ada")))
final class AccountTests: XCTestCase {
    @UITest
    func showsTheSignedInUser(app: XCUIApplication) {
        #expect(app[AccountID.userName].label == "Ada")
    }
}
```

A later payload of the same type replaces an earlier one. To give a payload a name
that reads better in a list of traits, see <doc:WritingTraits>.

## Arguments and environment variables

| Trait | Effect |
|---|---|
| `.launchArgument("--flag")` | Adds a launch argument. The app checks for it with `LaunchTraits.current.hasArgument(_:)`. |
| `.launchArguments(["-key", "value"])` | Adds several launch arguments, in order. |
| `.environment("NAME", "value")` | Sets a launch environment variable, replacing an earlier value for the same name. |

## Settings the system reads

These need no code in the app, because the system reads them for it.

| Trait | Effect |
|---|---|
| `.language("fr")` | Sets the app's preferred language for the launch, in the same way as choosing an app language in a scheme. The app shows that language if it is localised for it. |
| `.locale("fr_FR")` | Sets the app's region and formatting conventions. |
| `.dynamicTypeSize(.accessibility3)` | Launches the app with a Dynamic Type size, as if it were the text size chosen in Settings. The device's own setting is not changed. It has an effect on platforms whose apps are built with UIKit, such as iOS. |
| `.userDefault("key", true)` | Overrides a value that the app reads from `UserDefaults.standard`. Takes a `Bool`, `Int`, `Double` or `String`. The override lasts for that launch only and is not saved. |

```swift
@UITest(traits: .language("fr"), .dynamicTypeSize(.accessibility3), .userDefault("hasSeenOnboarding", true))
func titleStillFitsAtLargeSizes(app: XCUIApplication) { /* ... */ }
```

## Rotating the device

On iOS, `.orientation(_:)` rotates the device after the app has launched, and puts it
back when the test finishes. The app only follows if it supports the orientation.

```swift
@UITest(traits: .orientation(.landscapeLeft))
func showsTwoColumnsInLandscape(app: XCUIApplication) { /* ... */ }
```

## Running without animations

`.animationsDisabled` asks the app to run without animations, so that a test does not
wait for them. The app has to act on the request: in SwiftUI, with
`uiTestAnimationsDisabled()` from UITestingCore on its root view.

## Topics

### Data, arguments and environment

- ``UITestTrait/launch(_:)``
- ``UITestTrait/launchArgument(_:)``
- ``UITestTrait/launchArguments(_:)``
- ``UITestTrait/environment(_:_:)``

### Settings

- ``UITestTrait/language(_:)``
- ``UITestTrait/locale(_:)``
- ``UITestTrait/dynamicTypeSize(_:)``
- ``UITestTrait/orientation(_:)``
- ``UITestTrait/animationsDisabled``
