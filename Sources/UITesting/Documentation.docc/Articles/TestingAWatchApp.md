# Testing a watch app

Run the same tests against a watch app, where typing, alerts, steppers and sliders are different.

## Overview

A UI test target for a watch app uses the library in the same way, and a test that is
shared with an iOS app reads the same on both. XCTest reports a watch app differently
from an iOS one, and the library takes up the differences:

| In an iOS app | In a watch app | What the library does |
|---|---|---|
| A field is typed into where it is. | A tap on a field opens a screen with a keyboard, and the field has the text when that screen is closed. | `enter(_:)`, `replaceText(with:)` and `clear()` type on that screen and close it with its button for done. |
| Return submits a field. | A field is submitted whenever the screen to type on is closed. | `submit()` opens that screen and closes it. Every action that types submits the field as well. |
| An alert is an alert, and a confirmation dialog is a sheet. | Both are a screen with a table, with the title as the first text inside. | `app.alert` and `app.dialog` both find it, and `title`, `message` and `buttons` read it. |
| The button that cancels a dialog is one of its buttons. | It is a button to close the dialog, in the bar above it. | `app.dialog.dismiss()` taps it. |
| A stepper is a stepper. | It is the text of its label, with a button for each direction inside. | The kind `Stepper` matches an element of any type on watchOS, and `value`, `increment()` and `decrement()` work on it. |
| A slider has a thumb that is dragged. | A slider moves by a step at a time, with a tap on either end. | `adjust(to:)` taps until the slider is there, and fails if the position is between two steps. |
| A drag moves the content by its own length. | The content carries on for several times the length of a drag. | `scrollIntoView()` drags slowly, so that no row goes past unseen. |

A swipe of `scrollIntoView()` moves the content by about half the height of the screen,
which on a watch is less than two rows of a list. Pass a larger `maximumSwipes` for an
element that is far down:

```swift
try app[NumberID.row(60)].scrollIntoView(maximumSwipes: 60)
```

A slider with no `step` moves by a sixth of its range at a time on watchOS, so
`adjust(to: 0.83)` can be reached and `adjust(to: 0.8)` cannot.

Some things are not in a watch app, or are not reported by XCTest on watchOS, and the
library does not have them there: pull to refresh, picker wheels, the actions for date
pickers, `SystemAlert` and the `.systemAlerts` trait, the `.orientation` trait and
`context.background()`. watchOS has no pickers with segments or with a menu, and no
editor for several lines of text. It does not report the identifier of a button of an
alert, so tap such a button by its label.

Before watchOS 26 a text field has its identifier and its label on an element around
it, and not on the field. The library looks inside that element there, so
`app[ProfileID.nameField]` and `app.textField("Email")` find the field on every
version. A query of your own, such as `app.textFields["ProfileID.nameField"]`, does
not.

`context.open(_:)` opens a link in an app that is running, as on iOS. An app that is
not running is launched by the link without the arguments and environment of the
test, so its launch traits do not apply. Launch the app first.

## Running the tests

```bash
xcodebuild test -project Examples/Demo/Demo.xcodeproj -scheme Demo \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 12 (46mm)" -skipMacroValidation
```

runs the demo's UI tests against the demo as a watch app.
