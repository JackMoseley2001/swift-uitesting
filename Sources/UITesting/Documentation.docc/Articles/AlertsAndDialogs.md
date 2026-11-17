# Alerts and dialogs

Answer the alerts and confirmation dialogs that the app presents.

## Overview

SwiftUI gives no way to put an identifier on an alert or a confirmation dialog, so they
are reached through the app:

```swift
try app[DraftID.deleteButton].tap()

#expect(app.alert.title == "Delete the draft?")
try app.alert.tap("Delete")
```

`app.alert` is the alert that is showing. `app.dialog` is the confirmation dialog or
action sheet. Their actions wait for it to show, and a failed tap lists the buttons
there are:

```
Could not tap "Remove" in the alert "Delete the draft?": the alert has no button with
this label. Its buttons are: "Cancel", "Delete"
```

| Member | What it does |
| --- | --- |
| `tap("Delete")` | Taps the button with this label. |
| `tapButton(at: 0)` | Taps the button at this position. |
| `app.alert[DraftID.confirmDeleteButton]` | The button with an identifier, which does not depend on the language of the app. |
| `dismiss()` | Closes a dialog by a tap outside it. |
| `waitToAppear()`, `waitToDisappear()` | Wait for it to show or to go. |
| `isShowing`, `title`, `message`, `buttons` | Read it without waiting. |

- **Look identifiers up in the alert, not in the app.** XCTest reports a button of an
  alert twice, one inside the other, so `app[DraftID.confirmDeleteButton]` finds two
  elements and fails.
- **A dialog shown as a popover has no cancel button.** iOS 27 shows a confirmation
  dialog this way on an iPhone, and leaves out the button with the `cancel` role. Use
  `dismiss()`, which runs that button's action.
- **Sheets have nothing of their own.** The content of a `sheet` is ordinary elements
  with no container around them, so look them up in the app as usual.

An alert that the system shows, such as a request for permission, is not one of
these. See <doc:SystemAlerts>.

## Topics

### Reaching an alert or dialog

- ``AppAlert``
