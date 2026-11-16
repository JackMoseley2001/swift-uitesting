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

### Check the app

Use ``expect(_:_:within:)`` to check a condition. A failed expectation is recorded
against the test, which then carries on. Pass a timeout to wait for something that
does not happen immediately.

```swift
@UITest
func loadsTheMessage(app: XCUIApplication) {
    app.buttons["load-message-button"].tap()

    #expect(app.staticTexts["message"].exists, within: .seconds(5))
    #expect(app.staticTexts["message"].label == "Hello")
}
```

When a comparison with `==` fails, the message shows how the two values differ.

A wait blocks between checks in a test that is not `async`. In an `async` test, write
`await` before the macro, and the wait suspends the test instead, so other work on the
main actor can run while it waits.

```swift
@UITest
func loadsTheMessage(app: XCUIApplication) async {
    app.buttons["load-message-button"].tap()

    await #expect(app.staticTexts["message"].exists, within: .seconds(5))
}
```

Use `#require` when the rest of the test depends on the condition. It records the
failure and ends the test. It can also unwrap an optional value.

```swift
@UITest
func loadsTheMessage(app: XCUIApplication) throws {
    app.buttons["load-message-button"].tap()

    try #require(app.staticTexts["message"].exists, within: .seconds(5))
    let text = try #require(app.staticTexts["message"].value as? String)
    #expect(text == "Hello")
}
```

### Configure the launch

The built-in traits add launch arguments, environment variables and typed payloads.
The app reads them back with `LaunchTraits` from UITestingCore.

Others set things the system reads for you: `.language(_:)` and `.locale(_:)` choose
the language and region the app launches in, and `.userDefault(_:_:)` overrides a
value in the app's `UserDefaults` for that launch.

On iOS, `.orientation(_:)` rotates the device and `.appearance(_:)` switches between
light and dark mode. Both put the device back when the test finishes.

### Skip a test

`.disabled(_:)` skips a test, and `.enabled(if:_:)` and `.disabled(if:_:)` skip it
depending on a condition. The condition is evaluated when the test starts, before the
app is launched.

```swift
@UITest(traits: .disabled("Waiting for the new checkout screen"))
func completesAPurchase(app: XCUIApplication) { /* ... */ }
```

### Limit how long a test takes

Give a test, or a whole suite, a time limit. A test whose body runs past the limit
fails, and a wait in `#expect` or `#require` ends when the limit is reached.

```swift
@UITest(traits: .timeLimit(.seconds(15)))
func loadsTheFeed(app: XCUIApplication) async throws {
    try await #require(app.cells.firstMatch.exists, within: .seconds(30))
}
```

A call that is blocking the test, such as tapping or reading an element, cannot be
interrupted, so the failure is reported once that call returns.

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

### Expectations

- ``expect(_:_:within:)``
- ``UITestingExpect(_:_:within:)``
- ``RequirementFailedError``

### Traits

- ``UITestTrait``

### Configuring the launch

- ``LaunchArgumentsTrait``
- ``LaunchEnvironmentTrait``
- ``LaunchPayloadTrait``

### Skipping tests

- ``ConditionTrait``

### Limiting how long a test takes

- ``TimeLimitTrait``
