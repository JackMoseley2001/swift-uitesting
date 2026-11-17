# Writing your own traits

Package the set-up that your tests share as a trait, and give it a name that reads well where it is used.

## Overview

Conform to `UITestTrait`. Every requirement has a default that does nothing, so you
implement only what you need.

```swift
// Configures the launch.
struct SkipOnboarding: UITestTrait {
    func prepare(_ launch: inout LaunchConfiguration) {
        launch.arguments.append("--skip-onboarding")
    }
}

// Does something with the app just before it launches.
struct ForgetPhotosAccess: UITestTrait {
    func willLaunch(_ context: UITestContext) async throws {
        context.app.resetAuthorizationStatus(for: .photos)
    }
}

// Runs code around the test, without sending anything to the app.
struct Landscape: UITestTrait {
    func setUp(_ context: UITestContext) async throws {
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    func tearDown(_ context: UITestContext) async throws {
        XCUIDevice.shared.orientation = .portrait
    }
}
```

| Step | Runs |
|---|---|
| `prepare(_:)` | First, to build the launch arguments and environment. Throw `XCTSkip` here to skip the test. |
| `willLaunch(_:)` | Just before the app is launched, once it has its arguments and environment. |
| `setUp(_:)` | After the app has launched, before the test. With `.manualLaunch`, the app has not launched yet. |
| `tearDown(_:)` | After the test, whether it passed or failed, in reverse order. |

Each step runs for every trait before the next step starts. `tearDown(_:)` is called
for every trait whose `willLaunch(_:)` was called. If a trait's `willLaunch(_:)`
throws, the app is not launched and no trait is set up, but that trait and the ones
before it are still torn down, so what they did before the launch can be undone.

To use a trait with leading-dot syntax, add a static member:

```swift
extension UITestTrait where Self == SkipOnboarding {
    static var skipOnboarding: Self { SkipOnboarding() }
}

@UITest(traits: .skipOnboarding)
func opensTheHomeScreen(app: XCUIApplication) { /* ... */ }
```

For a walk through each kind of trait, see <doc:WritingACustomTrait>.

## Naming a payload

A payload that a test sends to the app is already a trait, made with
``UITestTrait/launch(_:)``. Give the states your tests use short names in the same way:

```swift
extension UITestTrait where Self == LaunchPayloadTrait<AuthState> {
    static var loggedOut: Self {
        .launch(AuthState(isLoggedIn: false))
    }

    static func loggedIn(as name: String) -> Self {
        .launch(AuthState(isLoggedIn: true, name: name))
    }
}
```

## Topics

### The protocol

- ``UITestTrait``
- ``UITestContext``
