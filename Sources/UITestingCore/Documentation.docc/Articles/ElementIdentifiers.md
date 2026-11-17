# Element identifiers

Give the app's elements typed identifiers that the app and its UI tests share.

## Overview

A UI test finds an element by its accessibility identifier. Written as strings, the
identifiers have to be kept the same in the app and in the tests by hand, two screens
can use the same string without anyone noticing, and every test has to know whether
the element is a button, a label or a text field.

A group of typed identifiers solves all three. Declare it in code that both the app
and the UI test target compile, as you do for a payload. Each member's type says what
kind of element it identifies:

```swift
import UITestingCore

enum LoginID: ElementIDs {
    static var title: StaticText { element() }
    static var emailField: TextField { element() }
    static var signInButton: Button { element() }
}
```

The app tags a view with a member, and a test finds the element with the same member:

```swift
// In the app
Button("Sign in") { signIn() }
    .accessibilityIdentifier(LoginID.signInButton)

// In a UI test
try app[LoginID.signInButton].tap()
#expect(app[LoginID.title].label == "Welcome")
```

`app[id]` looks for the kind of element the identifier declares, so
`app[LoginID.signInButton]` finds what `app.buttons["LoginID.signInButton"]` does.
`element[id]` looks only inside another element.

## Kinds of element

Inside a group, `Button`, `StaticText`, `TextField` and the rest are types of
identifier, one for each element type that XCTest reports. Some common ones:

| Kind | Matches |
|---|---|
| `Button` | Buttons, including a SwiftUI `NavigationLink`. |
| `StaticText` | Text the user cannot edit: a SwiftUI `Text`, a `UILabel`. |
| `TextField`, `SecureTextField`, `TextView` | A text field, a password field, and a multi-line editor. |
| `Switch` | A SwiftUI `Toggle` on iOS. On macOS it is a `CheckBox`. |
| `Slider`, `Stepper`, `Picker`, `DatePicker`, `SegmentedControl`, `MenuPicker` | Controls. A SwiftUI `Picker` is a different kind for each picker style: `Picker` for a wheel, `SegmentedControl`, and `MenuPicker` for a menu. |
| `Image`, `Link`, `Cell`, `Table`, `CollectionView`, `ScrollView` | Content and containers. |
| `AnyElement` | An element of any kind. |

The kind is what XCTest sees, which is not always what the SwiftUI view is called. If
the element exists but is a different kind from the one its identifier declares, the
test does not find it. When you are not sure, or the kind differs between platforms,
declare the identifier as `AnyElement`. The Accessibility Inspector, and
`print(app.debugDescription)` in a test, show the kind of each element.

## Clashes

The string an element gets is the name of the group, a full stop, and the name of the
member: `LoginID.signInButton` is `"LoginID.signInButton"`. So a `title` in `LoginID` and
a `title` in `SettingsID` are different identifiers, and within one group the compiler
stops two members from sharing a name. A nested type includes the types it is nested
in, so `LoginScreen.ID` and `SettingsScreen.ID` are kept apart too.

## Lists

Use a function to identify one element out of many, and pass its arguments on to
`element`:

```swift
enum InboxID: ElementIDs {
    static var list: CollectionView { element() }
    static func row(_ id: Int) -> Cell { element(id) }
    static func deleteButton(row: Int) -> Button { element(row) }
}

// In the app
ForEach(messages) { message in
    MessageRow(message)
        .accessibilityIdentifier(InboxID.row(message.id))
}

// In a UI test
try app[InboxID.row(1234)].tap()
```

`InboxID.row(1234)` is `"InboxID.row(1234)"`.

## Things to know

- **Computed properties, not `let`.** Write each identifier as a computed property or a
  function, as above. A stored property such as
  `static let title: StaticText = element()` cannot work out its own name, and every
  one in the group would get the same identifier.
- **Arguments.** Each argument is described the way `print` shows it. Use ones whose
  description does not change between runs, such as integers, strings and UUIDs.
- **Identifiers the app already has.** Create the identifier from the exact string:
  `static var signInButton: Button { Button("sign-in-button") }`.
- **Renaming.** The default identifiers follow the names in your code. To keep them
  stable, give the group its own `namespace`, or pass `name:` to `element`.
- **Choosing the query yourself.** Every query also takes an identifier, and ignores
  its kind: `app.tables.cells[InboxID.row(1234)]`.
- **UIKit and AppKit.** Set the element's identifier to the string:
  `button.accessibilityIdentifier = LoginID.signInButton.accessibilityIdentifier`.

## Topics

### Declaring identifiers

- ``ElementIDs``
- ``ElementID``

### Kinds of element

- ``ElementKind``
- ``ElementKinds``
- ``ElementType``
- ``TextEntryKind``
- ``SingleLineTextEntryKind``
- ``SwitchKind``
- ``PickerWheelKind``
