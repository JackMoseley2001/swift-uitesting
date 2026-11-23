# Testing a tvOS app

Run the same tests against a tvOS app, where the remote moves the focus and selects.

## Overview

An Apple TV has no touch screen. One element has the focus, the remote moves the focus
from element to element, and a press of the remote acts on whichever has it. XCTest
has no taps, drags or swipes on tvOS, and the library does the same work with the
remote, so that a test shared with an iOS app reads the same on both:

| In an iOS app | In a tvOS app | What the library does |
|---|---|---|
| An element is tapped. | The focus is moved to an element, and the remote selects it. | `tap()`, and every action that taps, moves the focus to the element and presses select. `select()` is `tap()` under the name it has on tvOS, and `focus()` moves the focus and presses nothing. |
| Content is scrolled by a drag. | Content scrolls as the focus moves through it. | `scrollIntoView()` presses the remote in a direction until the element is on the screen, and then moves the focus to it. |
| A field is typed into where it is. | A field that is selected opens a keyboard that fills the screen. | `enter(_:)`, `replaceText(with:)` and `clear()` select the field, type, and close the keyboard with the remote's menu button. |
| A navigation bar has a button to go back. | The remote's menu button goes back. | `app.goBack()` presses it. |
| A `List` is a collection view. | It is a table. | The kind `List` matches whichever it is. |
| The options of a menu are buttons. | They are the cells of a list. | `select(_:)` of a `MenuPicker` finds them. |

```swift
@UITest
func opensAFilm(app: XCUIApplication) throws {
    try app[LibraryID.poster(12)].scrollIntoView().tap()

    #expect(app.navigationTitle == "Solaris", within: .seconds(2))
    #expect(app[FilmID.playButton].hasFocus)
}
```

The focus is moved a press at a time towards the element: up or down if the element is
not level with the focus, and sideways if it is. An action fails if no press towards
the element moves the focus, and the message names what the focus stopped on. An
element that is off the screen has no frame on tvOS, so `tap()` cannot tell which way
it is: scroll to it first with `scrollIntoView()`. `hasFocus`
is a property of `XCUIElement`, so it can be read from any element. The focus counts
as being on an element when it is on something that holds it, such as the row of a
list that a button is in.

To press the remote yourself, use XCTest's `XCUIRemote.shared.press(_:)`.

tvOS has no sliders, steppers, swipe actions, pull to refresh, date pickers or editors
for several lines of text, and the library does not have their actions there. It also
does not have picker wheels, `SystemAlert` and the `.systemAlerts` trait, the
`.orientation` trait and `context.background()`. `dismiss()` on a dialog fails on tvOS,
because a dialog there has a button to cancel and does not close any other way.
Moving the focus onto a segment of a `SegmentedPicker` selects it, as it does for a
person.

## Running the tests

```bash
xcodebuild test -project Examples/Demo/Demo.xcodeproj -scheme Demo \
  -destination "platform=tvOS Simulator,name=Apple TV 4K (4th generation)" -skipMacroValidation
```

runs the demo's UI tests against the demo as a tvOS app.

## Topics

### Actions with the remote

- ``UITestElement/select(within:filePath:line:)``
- ``UITestElement/focus(within:filePath:line:)``
