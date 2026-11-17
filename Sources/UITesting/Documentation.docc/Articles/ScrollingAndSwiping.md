# Scrolling and swiping

Scroll to an element that a list has not created yet, pull a list to refresh it, and use the swipe actions of a row.

## Overview

A list only creates the rows near the ones on screen. A row further down does not
exist until the list is scrolled to it, so waiting for it does not help.
`scrollIntoView()` scrolls until the element is on screen and can be tapped, and
returns the element so that an action can follow:

```swift
try app[InboxID.row(1234)].scrollIntoView().tap()
```

- **Direction.** It looks down first, and when the content stops moving it goes back
  up, so it finds the element whichever side it is on. Pass a direction to start the
  other way, or sideways: `scrollIntoView(.up)`, `scrollIntoView(.right)`.
- **Where it scrolls.** In whatever the element was looked up in. `app[id]` drags the
  middle of the app, which scrolls the view under it. To scroll one particular view,
  look the element up in it: `app[InboxID.list][InboxID.row(1234)].scrollIntoView()`.
- **How far.** Each swipe moves the content by about half the height of the view, and
  takes about a second. It makes up to 20 before turning back. For a longer list, pass
  `maximumSwipes:`.
- **Failure.** If the element never comes into view, the failure is recorded at the
  line of the call and the test ends.

## Pull to refresh

```swift
try app[InboxID.list].pullToRefresh()
#expect(app[InboxID.row(1234)].exists, within: .seconds(5))
```

`pullToRefresh` waits for the list or scroll view, and drags it down from near its top.

- **It returns when the drag is done, not when the refresh is.** Wait for what the
  refresh brings with an expectation that has a timeout.
- **The content has to be at its top.** Otherwise the drag scrolls the content back up,
  as it does for a person.

## Swipe actions on a row

```swift
try app[InboxID.row(1234)].swipeAction("Archive")
try app[InboxID.row(1234)].swipeAction("Unread", edge: .leading)
try app[InboxID.row(1234)].swipeAction(InboxID.deleteButton(1234))
```

`swipeAction` waits for the row, swipes it, waits for the action and taps it. The
action is given by its label, or by an identifier, which does not depend on the
language of the app.

- **The swipe is slow**, so that it shows the actions and does not carry the first one
  out, as a full swipe does.
- **The action is looked for beside the row.** XCTest does not report a row's actions
  as part of the row, so the action is the match at the height of the row. The action
  of another row, or a button with the same label elsewhere, is not taken for it.
- **A failure lists the actions the swipe showed.**
- **Sides are for a left-to-right language.** `.trailing`, the default, swipes the row
  to the left.

## Topics

### Scrolling

- ``UITestElement/scrollIntoView(_:maximumSwipes:filePath:line:)``
- ``UITestElement/pullToRefresh(within:filePath:line:)``
- ``ScrollDirection``

### Swipe actions

- ``SwipeActionEdge``
