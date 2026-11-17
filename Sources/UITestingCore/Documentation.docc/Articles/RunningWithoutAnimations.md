# Running without animations

Let a UI test ask the app to run without animations, which makes tests faster and steadier.

## Overview

XCTest waits for the app to stop animating before each action, so animations add their
length to every test. The `.animationsDisabled` trait asks the app to run without them:

```swift
@UITestSuite(traits: .animationsDisabled)
final class InboxTests: XCTestCase { … }
```

The app has to act on the request, with one line on its root view:

```swift
import UITestingCore

@main
struct InboxApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .uiTestAnimationsDisabled()
        }
    }
}
```

The modifier does nothing unless a test asks, so it is safe to leave in the app. When
a test does ask:

- **Animations that UIKit runs** happen at once, everywhere in the app. These include
  pushes on a navigation stack and the presentation of sheets. In the demo, a push
  took about half as long.
- **SwiftUI's own animations**, from `withAnimation` or an `animation` modifier,
  happen at once in the view the modifier is on and the views inside it.

A screen that is pushed onto a navigation stack or presented as a sheet is a view
hierarchy of its own, which the modifier on the root view does not reach. Add the
modifier to those screens as well if they have SwiftUI animations:

```swift
.navigationDestination(for: Route.self) { route in
    RouteView(route)
        .uiTestAnimationsDisabled()
}
```

A UIKit app calls `LaunchTraits.current.applyAnimationSetting()` when it starts, which
covers the animations UIKit runs. The app can also read
`LaunchTraits.current.animationsDisabled` and decide for itself.

## Topics

### Acting on the request

- ``LaunchTraits/animationsDisabled``
- ``LaunchTraits/applyAnimationSetting()``
