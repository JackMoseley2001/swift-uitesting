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

### Find elements

Give elements typed identifiers with an `ElementIDs` group from UITestingCore, and a
test finds them with the same members that the app tagged them with. Each identifier
says what kind of element it is for, so the test does not have to.

```swift
@UITest
func deletesAMessage(app: XCUIApplication) throws {
    try app[InboxID.deleteButton(row: 1234)].tap()
    try app[InboxID.row(1234)].waitToDisappear()
}
```

`app[id]` looks for the kind of element the identifier declares, and `element[id]`
looks only inside another element. To choose the query yourself, pass the identifier
to it: `app.cells[InboxID.row(1234)]`.

### Act on elements

Looking an identifier up gives a ``UITestElement``. Its actions wait for the element to
be ready, where XCTest's own fail at once if the element is not there yet:
``UITestElement/tap(within:filePath:line:)`` waits until the element exists and is
enabled, and ``UITestElement/waitToAppear(within:filePath:line:)`` and
``UITestElement/waitToDisappear(within:filePath:line:)`` wait for it to come and go.

If the element is not ready in time, the failure is recorded at the line of the call
with a message that says why, and the test ends. Actions wait for up to 5 seconds, or
for the time set with `.actionTimeout(_:)` on the suite or the test.

The element's properties, such as `label` and `exists`, are read without waiting.

Switches, sliders, steppers, segmented controls and picker wheels have actions of
their own: ``UITestElement/setOn(_:within:filePath:line:)``,
``UITestElement/adjust(to:tolerance:within:filePath:line:)``,
``UITestElement/increment(times:within:filePath:line:)`` and `select(_:)`.

On iOS, a date picker is set with
``UITestElement/setDate(year:month:day:locale:within:filePath:line:)`` and
``UITestElement/setTime(hour:minute:locale:within:filePath:line:)``, which open its
calendar or its wheels if they have to.

A row further down a list does not exist until the list is scrolled to it. Scroll to
it with ``UITestElement/scrollIntoView(_:maximumSwipes:filePath:line:)``, which returns
the element so that an action can follow.

To refresh a list, pull it down with
``UITestElement/pullToRefresh(within:filePath:line:)``. To use a swipe action of a row in a list, call
`swipeAction(_:edge:)` on the row with the action's label, or with an identifier.

### Enter text

Elements whose identifier is declared as a text field, secure text field, search field
or text view can be typed into, with ``UITestElement/enter(_:within:filePath:line:)``,
``UITestElement/replaceText(with:within:filePath:line:)`` and
``UITestElement/clear(within:filePath:line:)``. ``UITestElement/text`` reads what a
field holds.

To press Return in a single-line field, use
``UITestElement/submit(within:filePath:line:)``.

### Answer alerts and dialogs

An alert or confirmation dialog that the app presents is reached through the app, with
``XCTest/XCUIApplication/alert`` and ``XCTest/XCUIApplication/dialog``:

```swift
try app.alert.tap("Delete")
try app.dialog.dismiss()
```

See ``AppAlert``.

### Answer system alerts

A permission alert belongs to the system and not to the app, so the app's identifiers
cannot find it. On iOS, ``SystemAlert/current`` reaches the one that is showing:

```swift
@UITest(traits: .resetAuthorization(for: .microphone))
func recordsAfterAccessIsAllowed(app: XCUIApplication) throws {
    try app[RecorderID.recordButton].tap()
    try SystemAlert.current.allow()

    #expect(app[RecorderID.status].label == "Recording")
}
```

``SystemAlert/allow(within:filePath:line:)`` and
``SystemAlert/deny(within:filePath:line:)`` work in any language. Other buttons are
tapped by label with ``SystemAlert/tap(_:within:filePath:line:)``, or by position with
``SystemAlert/tapButton(at:within:filePath:line:)``.

To answer alerts for a whole test or suite, use the
``UITestTrait/systemAlerts(_:for:)`` trait:

```swift
@UITest(traits: .systemAlerts(.allow, for: .microphone, .camera))
```

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

### Name the steps of a test

Wrap part of a test in `step(_:_:)` to give it a name. A failure
inside it starts with that name, and Xcode's test report lists what the step did
inside it. Steps are optional and can be nested.

When a test fails, a screenshot and the app's element hierarchy are attached to it.
``UITestTrait/failureAttachments(_:)`` turns that off.

### Configure the launch

The built-in traits add launch arguments, environment variables and typed payloads.
The app reads them back with `LaunchTraits` from UITestingCore.

Others set things the system reads for you: `.language(_:)` and `.locale(_:)` choose
the language and region the app launches in, `.dynamicTypeSize(_:)` chooses its text
size, and `.userDefault(_:_:)` overrides a value in the app's `UserDefaults` for that
launch.

On iOS, `.orientation(_:)` rotates the device for the test, and puts it back when the
test finishes.

### Launch the app again, or yourself

The app is launched before a test starts. Call ``UITestContext/relaunch(with:)`` to
end it and launch it again, which lets a test check what the app does across a
restart. Traits passed to the call are applied after the test's own traits.

```swift
@UITest(traits: .loggedIn(as: "Ada"))
func signsOutAcrossARestart(context: UITestContext) throws {
    try context.relaunch(with: .loggedOut)

    #expect(context.app.buttons["sign-in-button"].exists)
}
```

With `.manualLaunch`, the app is configured but not launched, so the test can do
something first and then call `launch()` on the app.

### Do something before the launch

`.resetAuthorization(for:)` makes the app forget whether it was given access to a
resource such as photos or the camera, so the system asks again during the test.

```swift
@UITest(traits: .resetAuthorization(for: .photos))
func asksForAccessToPhotos(app: XCUIApplication) {
    app.buttons["choose-photo-button"].tap()
    // ...
}
```

It does its work in the `willLaunch(_:)` step of ``UITestTrait``, which runs once the
app has its launch arguments and environment and before it is launched. Your own
traits can use the same step.

### Skip a test

`.disabled(_:)` skips a test, and `.enabled(if:_:)` and `.disabled(if:_:)` skip it
depending on a condition. The condition is evaluated when the test starts, before the
app is launched.

```swift
@UITest(traits: .disabled("Waiting for the new checkout screen"))
func completesAPurchase(app: XCUIApplication) { /* ... */ }
```

### Write your own traits

A ``UITestTrait`` can configure the launch, run code just before and after the app
launches, and clean up after the test. A trait does not have to send anything to the app.

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

### Finding and acting on elements

- ``UITestElement``
- ``ScrollDirection``
- ``SwipeActionEdge``
- ``AppAlert``
- ``SystemAlert``
- ``SystemAlertsTrait``
- ``SystemAlertAnswer``
- ``ActionTimeoutTrait``

### Steps and failures

- ``FailureAttachmentsTrait``
- ``AnimationsDisabledTrait``

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
- ``ManualLaunchTrait``
- ``ResetAuthorizationTrait``

### Changing the device

- ``OrientationTrait``

### Skipping tests

- ``ConditionTrait``

