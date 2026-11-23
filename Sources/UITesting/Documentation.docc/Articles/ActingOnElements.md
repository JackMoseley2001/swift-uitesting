# Acting on elements

Tap elements and wait for them, without pairing every action with a wait of your own.

## Overview

XCTest's own `tap()` fails at once if the element is not there yet, so tests end up
pairing every action with a wait. An element found by a typed identifier does the
waiting itself:

```swift
@UITest
func deletesAMessage(app: XCUIApplication) throws {
    try app[InboxID.row(1234)].tap()              // waits until it exists and is enabled
    try app[MessageID.deleteButton].tap()
    try app[InboxID.row(1234)].waitToDisappear()
}
```

| Action | Waits until |
|---|---|
| `tap()` | The element exists and is enabled, then taps it. |
| `waitToAppear()` | The element exists. |
| `waitToDisappear()` | The element no longer exists. |

Other kinds of element have more actions. See <doc:EnteringText>, <doc:Controls> and <doc:ScrollingAndSwiping>.

## When an element is not ready

If the element is not ready in time, the failure is recorded at the line of the call
and the test ends, so actions are written with `try`. The message says what went wrong:

```
Could not tap LoginID.signInButton: the button was still disabled after 5 seconds
```

```
Could not tap LoginID.title: no button with this identifier appeared within 5 seconds
An element of type staticText has this identifier. Is the identifier declared as the wrong kind?
```

Actions wait for up to 5 seconds. Change that for a suite or a test with the
`.actionTimeout(_:)` trait, or for one call with `within:`:

```swift
@UITestSuite(traits: .actionTimeout(.seconds(2)))
final class InboxTests: XCTestCase {
    @UITest
    func loadsALongThread(app: XCUIApplication) throws {
        try app[InboxID.row(1234)].tap()
        try app[ThreadID.spinner].waitToDisappear(within: .seconds(30))
    }
}
```

## The title of a screen, and going back

A screen in a navigation stack has a title and a button to go back, and neither has
an identifier of the app's. The app has both:

```swift
@UITest
func opensAMessageAndGoesBack(app: XCUIApplication) throws {
    try app[InboxID.row(1234)].tap()
    #expect(app.navigationTitle == "Message", within: .seconds(2))

    try app.goBack()
    #expect(app.navigationTitle == "Inbox", within: .seconds(2))
}
```

`navigationTitle` is the title of the screen that is showing, read without waiting, and
is empty if there is none. `goBack()` waits for the button to go back and taps it. The
label of that button is in the language of the app, and on iOS it is the title of the
screen before, so `goBack()` finds it by what the system calls it, which is the same in
every language. Before iOS 26 and visionOS 26 the system calls it nothing, and `goBack()` taps the first
button of the navigation bar.

Both work on iOS and on macOS, where the title is in the title bar of the window and
the button is in its toolbar.

## Things to know

- **Reading does not wait.** `app[id].label`, `exists` and the other properties of
  `XCUIElement` are read straight away. To wait for a value, use
  `#expect(…, within:)`.
- **The rest of `XCUIElement`.** `app[id]` is a `UITestElement`, not an `XCUIElement`.
  Use its `element` property for anything it does not have, such as
  `app[id].element.swipeUp()`.
- **Waits block.** An action blocks while it waits, in an `async` test too, in the same
  way as `waitForExistence(timeout:)`.
- **Elements found by a string.** `app.buttons["save"]` is a plain `XCUIElement`, with
  XCTest's own actions. For actions that wait on an element that has no identifier,
  find it by its label, as in `app.button("Save")`. See <doc:FindingElements>.

## Topics

### Actions

- ``UITestElement/tap(within:filePath:line:)``
- ``UITestElement/waitToAppear(within:filePath:line:)``
- ``UITestElement/waitToDisappear(within:filePath:line:)``

### Timeouts

- ``UITestTrait/actionTimeout(_:)``
- ``ActionTimeoutTrait``
