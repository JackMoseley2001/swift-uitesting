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

A function identifies one row at a time. For a test to ask for every row, to count
them or to check their order, declare the rows as a family. A family is a computed
property, whose type says what kind of element each row is and what type of value
tells one row from another:

```swift
enum InboxID: ElementIDs {
    static var list: CollectionView { element() }
    static var row: Cell.Family<Int> { family() }
    static func deleteButton(row: Int) -> Button { element(row) }
}
```

A family is called the way the function is, and gives the same string, so the app and
the tests that find one row stay as they are:

```swift
// In the app
MessageRow(message)
    .accessibilityIdentifier(InboxID.row(message.id))   // "InboxID.row(1234)"

// In a UI test
try app[InboxID.row(1234)].tap()
```

A test finds every element of the family with `all:`:

```swift
#expect(app[all: InboxID.row].count == 3)
#expect(app[all: InboxID.row].map(\.label) == ["Ada", "Grace", "Linus"])
try app[all: InboxID.row][0].tap()
```

| Member | Gives |
|---|---|
| `count`, `isEmpty` | How many elements of the family there are. |
| `elements` | The elements, in the order XCTest reports them, which for a list is normally the order they are in on screen. Loop over this. |
| `map` | A value from each element, in the same order. |
| `[0]` | The element at a position, counting from zero. |

`app[all:]` looks everywhere in the app. `app[InboxID.list][all: InboxID.row]` looks
only inside another element.

- **Nothing waits.** `count` and the rest say what the app shows at the moment they
  are read. To wait, pass a timeout:
  `#expect(app[all: InboxID.row].count == 3, within: .seconds(5))`.
- **A list that loads its rows as it is scrolled has only some of them.** A SwiftUI
  `List` or `LazyVStack`, like a table or a collection view, only creates the rows
  near the ones on screen. The count is of the rows that are loaded, not of the data
  behind the list.
- **Each element keeps to its row.** An element is the one that was at its position
  when the test asked for it. From then on it is found by its own identifier, as
  `app[InboxID.row(1234)]` finds it, so it is the same row after the list changes,
  and its actions wait and fail in the same way. Reading that identifier takes one
  more request to the app for each element.
- **A position that has no element yet** gives an element whose actions wait for
  one: `try app[all: InboxID.row][3].tap()` waits for a fourth row. If none comes,
  the failure names the element by its family and position, `InboxID.row(…)[3]`.
- **The kind matters**, as it does for one identifier. If the count is zero while
  the rows are on screen, the rows are probably a different kind of element from the
  one the family declares.
- **A function is still enough** when tests only ever look for one element at a time,
  and is how to write an identifier that takes more than one argument. A family takes
  one value. A function with one argument can become a family without any identifier
  changing. If the argument has a label, pass the function's name:
  `family(name: "deleteButton(row:)")`.

## Things to know

- **Computed properties, not `let`.** Write each identifier as a computed property or a
  function, as above. A stored property such as
  `static let title: StaticText = element()` cannot work out its own name, and every
  one in the group would get the same identifier. A debug build stops when it reaches
  one, with a message that names the group and says how to fix it. A release build
  does not check, and never stops for this.
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
- ``ElementIDFamily``

### Kinds of element

- ``ElementKind``
- ``ElementKinds``
- ``ElementType``
- ``TextEntryKind``
- ``SingleLineTextEntryKind``
- ``SwitchKind``
- ``PickerWheelKind``
