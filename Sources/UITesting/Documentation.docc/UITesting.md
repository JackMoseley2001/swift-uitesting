# ``UITesting``

Launch your app for a UI test with reusable traits that configure the launch and the test.

## Overview

UITesting runs on top of XCTest's UI testing support. You mark a test case and its
tests with macros, and each test is launched with the traits you give it.

Link UITesting to your UI test target only. The app itself links UITestingCore, which
UITesting re-exports.

### Write a test

Mark the test case with ``UITestSuite(traits:)`` and each test with ``UITest(traits:)``.
A test can take the launched app as a parameter.

```swift
import UITesting
import XCTest

@UITestSuite(traits: .launch(AuthState(isLoggedIn: false)))
final class LoginTests: XCTestCase {
    @UITest
    func showsSignInButton(app: XCUIApplication) {
        XCTAssertTrue(app.buttons["Sign in"].exists)
    }

    @UITest(traits: .launch(AuthState(isLoggedIn: true)))
    func skipsSignInWhenAuthenticated(app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["Home"].exists)
    }
}
```

The suite's traits apply to every test in the suite, and a test's own traits are
applied after them, so a test can override its suite.

To run a test without the macros, conform the test case to ``UITestSuite`` and call
``UITestRunner/run(_:traits:body:)`` from a test method.

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

- ``UITestSuite(traits:)``
- ``UITest(traits:)``
- ``UITestRunner``
- ``UITestSuite``
- ``UITestContext``

### Traits

- ``UITestTrait``

### Configuring the launch

- ``LaunchArgumentsTrait``
- ``LaunchEnvironmentTrait``
- ``LaunchPayloadTrait``
