# Reading launch data in the app

Find out in the app what the UI test that launched it asked for.

## Overview

A UI test runs in a separate process from the app, so it configures the app through
its launch arguments and launch environment. ``LaunchTraits`` reads them back.

`LaunchTraits.current` gives the app what the test sent:

```swift
let traits = LaunchTraits.current

traits.isUITesting                          // true when a UI test launched the app
traits.hasArgument("--skip-onboarding")     // a launch argument
traits[AuthState.self]                      // a payload, or nil if none was sent
```

In SwiftUI, the same value is in the environment, and previews can override it:

```swift
struct PromoBanner: View {
    @Environment(\.launchTraits) private var launchTraits

    var body: some View {
        if launchTraits.hasArgument("--show-promo-banner") {
            Text("Free delivery this week")
        }
    }
}

#Preview {
    PromoBanner()
        .environment(\.launchTraits, LaunchTraits(arguments: ["--show-promo-banner"]))
}
```

## Things to know

- **Release builds.** `LaunchTraits.current` is always empty in a release build, so a
  shipped app cannot be reconfigured through its environment. If you run UI tests
  against a release build, use `LaunchTraits(processInfo: .processInfo)` instead.
- **Size.** Payloads travel in the launch environment as JSON. Keep them small, and send
  a reference to large data, such as the name of a bundled fixture, not the data itself.
- **Mismatches.** If a payload is present but cannot be decoded, the app stops with an
  assertion failure in a debug build. Use `payload(_:)` to handle the error yourself.

## Sharing payload types

A ``LaunchPayload`` is a `Codable` value that a test sends to the app. Its type must be
compiled into both the app and the UI test target: put it in a framework or package
that both link, or add its source file to both targets.

```swift
import UITestingCore

struct AuthState: LaunchPayload {
    var isLoggedIn: Bool
    var name: String?
}
```

## Describing a launch without the UITesting library

In a UI test, the traits of the UITesting library build the launch for you. A
``LaunchConfiguration`` does the same job by hand, for a test that does not use them:

```swift
var launch = LaunchConfiguration()
launch.arguments.append("--skip-onboarding")
try launch.setPayload(AuthState(isLoggedIn: false))

let app = XCUIApplication()
app.launchArguments = launch.arguments
app.launchEnvironment = launch.environment
app.launch()
```

## Topics

### Reading the launch

- ``LaunchTraits``

### Payloads

- ``LaunchPayload``
- ``LaunchPayloadDecodingError``

### Describing a launch

- ``LaunchConfiguration``
