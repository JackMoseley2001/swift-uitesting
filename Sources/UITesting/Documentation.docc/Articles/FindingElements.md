# Finding elements

Look elements up by the typed identifiers that the app gave them.

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

Each lookup gives a ``UITestElement``, whose actions wait for the element to be
ready, as <doc:ActingOnElements> describes.

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

## Elements found by a string

`app.buttons["save"]` is a plain `XCUIElement`, with XCTest's own actions, and works in
a test as it always has. Typed identifiers are optional.

## Topics

### Elements

- ``UITestElement``
