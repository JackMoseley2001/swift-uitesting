# Testing a Mac app

Run the same tests against a Mac app, where XCTest clicks, reads text and reports controls differently.

## Overview

A UI test target for a Mac app uses the library in the same way, and a test that is
shared with an iOS app reads the same on both. XCTest reports a Mac app differently
from an iOS one, and the library takes up the differences:

| In an iOS app | In a Mac app | What the library does |
|---|---|---|
| An element is tapped. | A tap does nothing. An element is clicked. | `tap()`, and every action that taps, clicks on macOS. `click()` is `tap()` under the name it has on a Mac. |
| Text reports what it says as its label. | Text reports what it says as its value, and has no label. | `label` is the text on both, and so is a lookup by label such as `app.staticText("Welcome")`. |
| A `Picker` with the `segmented` style is a segmented control. | It is a group of radio buttons. | The kind `SegmentedPicker` matches whichever it is, and has `selection` and `select(_:)`. |
| A `List` is a collection view. | It is an outline. | The kind `List` matches whichever it is. |
| A `Picker` with the `menu` style is a button. | It is a pop-up button. | The kind `MenuPicker` matches whichever it is. |
| A `Toggle` is a switch. | It is a checkbox. | `CheckBox` has `isOn`, `setOn(_:)` and `toggle()`, as `Switch` has. Declare the identifier as the kind for the platform. |
| An alert is an alert, and a confirmation dialog is a sheet. | Both are sheets on the window, with the title as the first text inside. | `app.alert` and `app.dialog` both find the sheet, and `title`, `message` and `buttons` read it. |
| The title of a screen is in the navigation bar, and so is the button to go back. | The title is in the title bar of the window, and the button is in its toolbar. | `app.navigationTitle` and `app.goBack()` use whichever it is. |
| A stepper reports its value as text. | It reports its value as a number. | `value` of a `Stepper` is the same text on both. |
| Content is scrolled by a drag. | Content is scrolled by the scroll wheel. | `scrollIntoView()` turns the wheel on macOS. |
| The app starts with nothing on screen from before. | The app opens the windows it had when it last ran. | The app is launched with `-ApplePersistenceIgnoreState YES`, and the test starts once the first window is there. The wait is as long as the test's `.actionTimeout`, or the `within:` of `relaunch` and `open`. |

```swift
enum SettingsID: ElementIDs {
    static var sizePicker: SegmentedPicker { element() }
    static var list: List { element() }

    #if os(macOS)
    static var notificationsToggle: CheckBox { element() }
    #else
    static var notificationsToggle: Switch { element() }
    #endif
}
```

Some things are not in a Mac app, or are not in XCTest on macOS, and the library does
not have them there: pull to refresh, picker wheels, the actions for date pickers,
`SystemAlert` and the `.systemAlerts` trait, the `.orientation` trait and
`context.background()`. `dismiss()` on a dialog fails on macOS, because a dialog there
does not close when clicked outside. The `.dynamicTypeSize` trait has no effect on a
Mac app.

## Messages need an entitlement

Xcode runs the UI tests of a Mac app in a sandbox, which does not let them listen for
the app to connect. A test with the `.messageChannel` trait fails with "Operation not
permitted" unless the UI test target has an entitlements file with:

```xml
<key>com.apple.security.network.server</key>
<true/>
```

Set it as the target's Code Signing Entitlements. An app that is sandboxed itself
needs `com.apple.security.network.client` to connect to the test.

## Running the tests

UI tests of a Mac app use the pointer and the keyboard of the Mac they run on, so
leave it alone while they run.

```bash
xcodebuild test -project Examples/Demo/Demo.xcodeproj -scheme Demo \
  -destination "platform=macOS" -skipMacroValidation
```

runs the demo's UI tests against the demo as a Mac app.

## Topics

### Clicking

- ``UITestElement/click(within:filePath:line:)``

### Reading text

- ``UITestElement/label``
