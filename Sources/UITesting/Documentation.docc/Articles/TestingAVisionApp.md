# Testing a visionOS app

Run the same tests against a visionOS app, where scrolling and the cursor of a field are different.

## Overview

A UI test target for a visionOS app uses the library in the same way. Most of what
XCTest reports is the same as for an iOS app, and the library takes up what is not:

| In an iOS app | In a visionOS app | What the library does |
|---|---|---|
| A drag anywhere in the app scrolls the view under it. | The app itself cannot be dragged, and a drag that holds at its end moves nothing. | `scrollIntoView()` swipes slowly. For an element looked up in the app, it swipes the app's first list or scroll view. |
| A tap in a field puts the cursor where the tap was. | A tap puts the cursor at the start of the text. | `clear()` and `replaceText(with:)` move the cursor to the end with the keyboard. |
| A slider's thumb is found from the slider's value. | The slider reports its thumb as an element inside it. | `adjust(to:)` drags that element. |
| The label of a stepper is the label of the control. | A stepper has no label. | Read `value`, which is the same on both. |

To scroll one particular view, look the element up in it, as on every platform:

```swift
try app[InboxID.list][InboxID.row(1234)].scrollIntoView()
```

Some things are not in a visionOS app, or are not in XCTest on visionOS, and the
library does not have them there: picker wheels, the actions for date pickers,
`SystemAlert` and the `.systemAlerts` trait, the `.orientation` trait and
`context.background()`. `dismiss()` on a dialog fails on visionOS, because a dialog
there does not close when tapped outside. XCTest cannot take a picture of the screen
on visionOS, so a failure has the element hierarchy attached and no screenshot.

## Running the tests

```bash
xcodebuild test -project Examples/Demo/Demo.xcodeproj -scheme Demo \
  -destination "platform=visionOS Simulator,name=Apple Vision Pro" -skipMacroValidation
```

runs the demo's UI tests against the demo as a visionOS app.
