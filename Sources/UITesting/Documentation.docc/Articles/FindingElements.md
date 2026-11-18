# Finding elements

Look elements up by the typed identifiers that the app gave them, or by their labels
where the app cannot give them one.

## Overview

The app and its UI tests share groups of typed identifiers, declared with `ElementIDs`
from UITestingCore. The app tags a view with a member of a group, and a test finds the
element with the same member:

```swift
// Compiled into the app and the UI test target
enum InboxID: ElementIDs {
    static var list: CollectionView { element() }
    static var composeButton: Button { element() }
    static func row(_ id: Int) -> Cell { element(id) }
}

// In a UI test
@UITest
func opensAMessage(app: XCUIApplication) throws {
    try app[InboxID.row(1234)].tap()
}
```

Each identifier says what kind of element it is for, so the test does not have to.
The UITestingCore documentation describes how to declare a group.

## Where to look

| Lookup | Finds |
|---|---|
| `app[InboxID.composeButton]` | The element anywhere in the app, of the kind the identifier declares. This is what `app.buttons["InboxID.composeButton"]` finds. |
| `app[InboxID.list][InboxID.row(1234)]` | The element inside another element. |
| `app.tables.cells[InboxID.row(1234)]` | The element in a query you choose. The kind that the identifier declares is not used. |
| `app[all: InboxID.row]` | Every element of a family of identifiers, such as all the rows of a list. See below. |

Each lookup of one element gives a ``UITestElement``, whose actions wait for the
element to be ready, as <doc:ActingOnElements> describes.

## Every element of a list

A function such as `InboxID.row(_:)` identifies one row at a time. For a test to ask
for every row, to count them or to check their order, the group declares the rows as
a family, which is called the way the function is and gives the same identifiers:

```swift
enum InboxID: ElementIDs {
    static var list: CollectionView { element() }
    static var row: Cell.Family<Int> { family() }
}
```

Look one row up as before, and all of them with `all:`, which gives a
``UITestElements``:

```swift
try app[InboxID.row(1234)].tap()

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

## When an element is not found

- **The kind is what XCTest sees**, which is not always what the SwiftUI view is
  called. If the element exists but is a different kind from the one its identifier
  declares, it is not found, and the failure of an action says so:

  ```
  Could not tap LoginID.title: no button with this identifier appeared within 5 seconds
  An element of type staticText has this identifier. Is the identifier declared as the wrong kind?
  ```

  Declare the identifier as `AnyElement` when the kind differs between platforms.
- **A row further down a list does not exist yet.** Scroll to it, as
  <doc:ScrollingAndSwiping> describes.
- **The element hierarchy is attached to a failed test**, with the type, identifier
  and label of every element the app had. See <doc:StepsAndFailures>.

## Elements without an identifier

An identifier needs the app's own code to tag the view. A page in a web view, a screen
that another library shows and an interface that the system provides have none, and a
test of them falls back to `app.buttons["Continue"].tap()`, which does not wait and
fails with XCTest's own message. Find such an element by its kind and its label:

```swift
try app.textField("Email").enter("ada@example.com")
try app.button("Continue").tap()
#expect(app.staticText("Welcome back").exists, within: .seconds(5))
```

The result is a ``UITestElement``, the same type that `app[id]` gives, so its actions
wait, and a failure says what was looked for:

```
Could not tap the button labelled "Continue": no button with this label appeared within 5 seconds
An element of type staticText has this label. Should the lookup be for that kind?
```

| Lookup | Finds |
|---|---|
| `button("Continue")` | A button. |
| `staticText("Welcome back")` | Text the user cannot edit. Its label is what it says. |
| `link("Terms")` | A link. |
| `textField("Email")`, `secureTextField("Password")` | A text field and a password field. |
| `switch("Notifications")` | A switch, such as a SwiftUI `Toggle` on iOS. |
| `cell("Wi-Fi")` | A cell of a table or a collection view. |
| `image("Company logo")` | An image. |
| `element(ElementKinds.Slider.self, labeled: "Volume")` | An element of any other kind. `ElementKinds.AnyElement.self` matches an element of every kind. |

Use a lookup on the app to look everywhere, or on an element to look only inside it.
The element can be one found by an identifier, one found by a label, or a plain
`XCUIElement`:

```swift
try app[BasketID.row(3)].button("Remove").tap()
try app.webViews.firstMatch.link("Terms").tap()
```

Things to know:

- **Identifiers are still the way to find the app's own views.** A label changes with
  the wording of the app and with its language, and an identifier does not. Lookups by
  label are for what the app cannot tag.
- **The whole label.** The label has to equal the string, in the same case. Part of a
  label does not match. Nor does an identifier, a title, a value or a placeholder, all
  of which `app.buttons["Continue"]` matches as well.
- **A field is found by its label**, not by the text it holds or by its placeholder.
  The Accessibility Inspector, and `print(app.debugDescription)` in a test, show the
  label of each element.
- **Several elements with the same label.** A lookup does not take the first of them.
  An action ends the test and says how many there were:

  ```
  Could not tap the button labelled "Remove": 2 elements match, and a lookup by label does not
  choose between them. Look inside the element that holds the one you mean
  ```

  To do that, start from the element, as in `app[BasketID.row(3)].button("Remove")`.
  Only the actions that wait check this. A property read from the element, such as
  `label`, and ``UITestElement/scrollIntoView(_:maximumSwipes:filePath:line:)`` fail
  with XCTest's own message about multiple matching elements.
- **No identifier.** The ``UITestElement/accessibilityIdentifier`` of an element found
  by its label is an empty string.

## Elements found by a string

`app.buttons["save"]` is a plain `XCUIElement`, with XCTest's own actions, and works in
a test as it always has. Typed identifiers are optional.

## Topics

### Elements

- ``UITestElement``
- ``UITestElements``

### Elements without an identifier

- ``UITestElement/element(_:labeled:)``
- ``UITestElement/button(_:)``
- ``UITestElement/staticText(_:)``
- ``UITestElement/link(_:)``
- ``UITestElement/textField(_:)``
- ``UITestElement/secureTextField(_:)``
- ``UITestElement/switch(_:)``
- ``UITestElement/cell(_:)``
- ``UITestElement/image(_:)``
