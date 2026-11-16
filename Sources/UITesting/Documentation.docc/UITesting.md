# ``UITesting``

Launch your app for a UI test with reusable traits that configure the launch and the test.

## Overview

UITesting runs on top of XCTest's UI testing support. A test hands its body to
``UITestRunner``, which launches the app and applies the test's traits around it.

Link UITesting to your UI test target only. The app itself links UITestingCore, which
UITesting re-exports.

### Run a test

Conform the test case to ``UITestSuite`` and call
``UITestRunner/run(_:traits:body:)`` from a test method.

```swift
import UITesting
import XCTest

final class LoginTests: XCTestCase, UITestSuite {
    static var suiteTraits: [any UITestTrait] {
        [.launch(AuthState(isLoggedIn: false))]
    }

    @MainActor
    func testShowsSignInButton() async throws {
        try await UITestRunner.run(self, traits: [.launchArgument("--skip-onboarding")]) { context in
            XCTAssertTrue(context.app.buttons["Sign in"].exists)
        }
    }
}
```

The suite's traits apply to every test in the suite, and a test's own traits are
applied after them, so a test can override its suite.

### Configure the launch

The built-in traits add launch arguments, environment variables and typed payloads.
The app reads them back with `LaunchTraits` from UITestingCore.

### Write your own traits

A ``UITestTrait`` can configure the launch, run code after the app has launched, and
clean up after the test. A trait does not have to send anything to the app.

```swift
struct DismissSystemAlerts: UITestTrait {
    func setUp(_ context: UITestContext) async throws {
        context.testCase.addUIInterruptionMonitor(withDescription: "System alert") { alert in
            alert.buttons["Allow"].tap()
            return true
        }
    }
}

extension UITestTrait where Self == DismissSystemAlerts {
    static var dismissSystemAlerts: Self { DismissSystemAlerts() }
}
```

## Topics

### Running tests

- ``UITestRunner``
- ``UITestSuite``
- ``UITestContext``

### Traits

- ``UITestTrait``

### Configuring the launch

- ``LaunchArgumentsTrait``
- ``LaunchEnvironmentTrait``
- ``LaunchPayloadTrait``
