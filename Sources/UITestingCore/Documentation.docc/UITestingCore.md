# ``UITestingCore``

Read the launch arguments, environment and typed payloads that a UI test passes to your app.

## Overview

A UI test runs in a separate process from the app it drives, so the only way to
configure the app before it starts is through its launch arguments and launch
environment. UITestingCore gives both sides a shared, typed way to use them.

Link UITestingCore to your app target. It has no dependency on XCTest, so it is
safe to ship in the app.

### Describe the launch in the UI test

A ``LaunchConfiguration`` collects the arguments and environment for one launch.
Use arguments for simple flags, and a ``LaunchPayload`` for structured values.

```swift
var launch = LaunchConfiguration()
launch.arguments.append("--skip-onboarding")
try launch.setPayload(AuthState(isLoggedIn: false))

let app = XCUIApplication()
app.launchArguments = launch.arguments
app.launchEnvironment = launch.environment
app.launch()
```

### Read the launch in the app

``LaunchTraits/current`` exposes the same values to the app.

```swift
let traits = LaunchTraits.current

if traits.hasArgument("--skip-onboarding") {
    onboarding.markAsSeen()
}

if let auth = traits[AuthState.self] {
    session.override(isLoggedIn: auth.isLoggedIn, userID: auth.userID)
}
```

### Share payload types between the app and its tests

A payload type must be compiled into both the app and the UI test target. Put it in a
framework or package that both link, or add its source file to both targets.

```swift
import UITestingCore

struct AuthState: LaunchPayload {
    var isLoggedIn: Bool
    var userID: String?
}
```

### Release builds

``LaunchTraits/current`` is always empty in release builds, so a shipped app cannot be
reconfigured through its arguments or environment. If you run UI tests against a
release build, create the traits with ``LaunchTraits/init(processInfo:)`` instead.

## Topics

### Reading the launch in the app

- ``LaunchTraits``

### Defining payloads

- ``LaunchPayload``
- ``LaunchPayloadDecodingError``

### Describing a launch in a UI test

- ``LaunchConfiguration``
