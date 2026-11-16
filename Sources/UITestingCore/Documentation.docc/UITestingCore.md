# ``UITestingCore``

Read the launch arguments, environment and typed payloads that a UI test passes to your app,
and give its elements typed identifiers that the test can find them by.

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

### Read the launch in SwiftUI views

In SwiftUI, the same traits are available from the environment as `launchTraits`.
The value defaults to ``LaunchTraits/current``, and previews and unit tests can
override it.

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

Environment values are not available in a view's initialiser, so read
``LaunchTraits/current`` directly when setting up a view's initial state.

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

### Identify elements for UI tests

An ``ElementIDs`` group holds typed accessibility identifiers that the app and its UI
tests share, so neither writes an identifier as a string. Declare the group in code
that both targets compile. The type of each member says what kind of element it
identifies, so a test does not have to.

```swift
enum InboxID: ElementIDs {
    static var title: StaticText { element() }
    static var composeButton: Button { element() }
    static func row(_ id: Int) -> Cell { element(id) }
}

ForEach(messages) { message in
    MessageRow(message)
        .accessibilityIdentifier(InboxID.row(message.id))
}
```

Each identifier is prefixed with the name of its group, so two groups can use the same
member name without their identifiers clashing. A function identifies one element out
of many, such as the row for a particular item.

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

### Identifying elements

- ``ElementIDs``
- ``ElementID``
- ``ElementKind``
- ``ElementKinds``
- ``ElementType``

### Describing a launch in a UI test

- ``LaunchConfiguration``
