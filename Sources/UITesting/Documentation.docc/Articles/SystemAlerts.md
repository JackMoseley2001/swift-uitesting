# System alerts and permissions

Answer the permission alerts that the system shows over the app, in a test or with a trait.

## Overview

An alert that the system shows over the app, such as a request for permission, is not
part of the app, so the app's identifiers cannot find it. `SystemAlert.current` reaches
the one that is showing:

```swift
@UITest(traits: .resetAuthorization(for: .microphone))
func recordsAfterAccessIsAllowed(app: XCUIApplication) throws {
    try app[RecorderID.recordButton].tap()
    try SystemAlert.current.allow()

    #expect(app[RecorderID.status].label == "Recording")
}
```

Its actions wait for an alert to show, as the actions on elements do, and a failure
says what went wrong:

```
Could not tap "Nope" in the system alert "Allow “Demo” to access your microphone?":
the alert has no button with this label. Its buttons are: "Don’t Allow", "Allow"
```

| Call | What it does |
| --- | --- |
| `allow()` | Taps the button that gives the app what it asked for. |
| `deny()` | Taps the button that refuses. |
| `tap("Allow Once")` | Taps the button with this label. |
| `tapButton(at: 0)` | Taps the button at this position. |
| `waitToAppear()`, `waitToDisappear()` | Wait for an alert to show or to go. |
| `isShowing`, `title`, `buttons` | Read the alert without waiting. |

- **`allow()` and `deny()` work in any language, on the alerts that support them.**
  Some alerts mark these two buttons with identifiers, and that is how they are found.
  An alert that does not mark its buttons fails with a list of the buttons it has. On
  iOS 27.2:

  | Alert | `allow()` | `deny()` |
  | --- | --- | --- |
  | Camera, microphone | Yes | Yes |
  | Photos | Yes, as "Allow Full Access" | Yes |
  | Contacts | No. Its other button is "Continue". | Yes |
  | Location, notifications | No. Use the label. | No. Use the label. |

  Before iOS 27 no alert marks its buttons. On those versions, `allow()` and `deny()`
  work on any alert that has two buttons: the first refuses and the second allows, in
  every language. They fail on an alert with more buttons, such as the one for
  location.
- **Labels are in the language of the device.** The system writes them, and a trait
  such as `.language("fr")` changes the app's language but not the alert's. Labels use
  a typographic apostrophe, as in "Don’t Allow".
- **Pair it with `.resetAuthorization(for:)`.** The system only asks once, so without a
  reset the alert shows on the first run and never again.
- **A failed test does not leave its alert behind.** A permission alert stays on the
  screen after the app that asked has ended. If a test fails while one is showing, and
  the alert marks the button that refuses, it is refused, so that the next test does
  not start underneath it.
- **iOS and iPadOS only.**

## Resetting a permission

The system asks for a permission once, and remembers the answer. The
`.resetAuthorization(for:)` trait makes the app forget whether it was given access to
a resource, before it launches, so that the system asks again during the test:

```swift
@UITest(traits: .resetAuthorization(for: .photos))
func asksForAccessToPhotos(app: XCUIApplication) throws {
    try app[ProfileID.choosePhotoButton].tap()
    try SystemAlert.current.deny()

    #expect(app[ProfileID.photoAccessMessage].exists)
}
```

## Answering alerts with a trait

The `.systemAlerts(_:for:)` trait answers alerts for a whole test or suite, so that the
test does not have to:

```swift
@UITest(traits: .systemAlerts(.allow, for: .microphone, .camera))
func recordsAVideo(app: XCUIApplication) throws {
    try app[RecorderID.recordButton].tap()

    #expect(app[RecorderID.status].label == "Recording", within: .seconds(5))
}
```

- **It resets the resources it names** before the launch, as `.resetAuthorization(for:)`
  does, so that the system asks again and gets this answer. `.systemAlerts(.allow)`
  without resources answers every alert it can and resets nothing.
- **The answer is `.allow`, `.deny` or `.button("Label")`.** `.allow` and `.deny` work
  on the alerts in the table above. Location and notifications need the label:
  `.systemAlerts(.button("Allow While Using App"), for: .location)`.
- **A test can give several, and can override its suite.** The last trait that is for
  an alert, and whose button the alert has, decides:

  ```swift
  @UITestSuite(traits: .systemAlerts(.allow))
  final class RecorderTests: XCTestCase {
      @UITest(traits: .systemAlerts(.deny, for: .microphone))
      func explainsThatItNeedsTheMicrophone(app: XCUIApplication) throws { /* ... */ }
  }
  ```

- **A trait for the camera, the microphone, photos or contacts answers only those
  alerts.** The alerts for other resources cannot be told apart, so a trait that names
  one of them answers every alert that has its button.
- **A trait that names resources answers alerts from iOS 27 only.** Before iOS 27 no
  alert says which resource it asks for, so the trait could not leave the alerts of
  other resources alone. On those versions it still resets the resources, and leaves
  the alert for the test to answer, with `try SystemAlert.current.allow()` for example.
  A trait without resources, such as `.systemAlerts(.allow)`, answers every alert on
  any version.
- **When the answer is given.** While an action or expectation of this library waits,
  and when the alert gets in the way of an action on the app. An alert that no trait
  answers is left for the test to answer with `SystemAlert`.
- **Alerts the app presents itself** are part of the app. Give their buttons
  identifiers and look them up in the app as usual.

## Topics

### Answering an alert in a test

- ``SystemAlert``

### Answering alerts with a trait

- ``UITestTrait/systemAlerts(_:for:)``
- ``SystemAlertsTrait``
- ``SystemAlertAnswer``

### Resetting permissions

- ``UITestTrait/resetAuthorization(for:)``
- ``ResetAuthorizationTrait``
