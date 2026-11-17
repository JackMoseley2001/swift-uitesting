# ``UITestingCore``

Read what a UI test passes to your app at launch, and give the app's elements typed identifiers that tests find them by.

## Overview

A UI test runs in a separate process from the app it drives. UITestingCore is the part
of the package that both sides share: the app links it to read what a test asked for
and to tag its elements, and the UI test target gets it through the UITesting library.

Link UITestingCore to your app target. It has no dependency on XCTest, so it is safe
to ship in the app.

```swift
import UITestingCore

// What a test asked for at launch
if let auth = LaunchTraits.current[AuthState.self] {
    session.override(isLoggedIn: auth.isLoggedIn, name: auth.name)
}

// An identifier that the app and its tests share
Button("Sign in") { signIn() }
    .accessibilityIdentifier(LoginID.signInButton)
```

### What is in the library

- **Launch data.** ``LaunchTraits`` gives the app the arguments, environment and typed
  payloads of its launch. See <doc:ReadingLaunchData>.
- **Element identifiers.** An ``ElementIDs`` group holds typed accessibility
  identifiers, so that neither the app nor a test writes one as a string. See
  <doc:ElementIdentifiers>.
- **Animations.** A test can ask the app to run without them. See
  <doc:RunningWithoutAnimations>.

### Release builds

``LaunchTraits/current`` is always empty in release builds, so a shipped app cannot be
reconfigured through its arguments or environment. If you run UI tests against a
release build, create the traits with ``LaunchTraits/init(processInfo:)`` instead.

## Topics

### Launch data

- <doc:ReadingLaunchData>

### Elements

- <doc:ElementIdentifiers>

### Animations

- <doc:RunningWithoutAnimations>
