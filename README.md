# swift-uitesting

Macros and traits that make XCUITest suites read like Swift Testing.

```swift
import UITesting
import XCTest

@UITestSuite(traits: .loggedIn(as: "Ada"))
final class AccountTests: XCTestCase {
    @UITest
    func showsTheSignedInUser(app: XCUIApplication) {
        #expect(app.staticTexts["user-name"].label == "Ada")
    }

    @UITest(traits: .loggedOut)
    func showsSignInWhenSignedOut(app: XCUIApplication) throws {
        try #require(app.buttons["sign-in-button"].exists, within: .seconds(5))
    }
}
```

Swift Testing does not run UI tests, so UI tests still have to be written with XCTest.
This package sits on top of XCTest's UI testing support and gives you:

- **`@UITestSuite` and `@UITest`**, which generate the code that launches the app for each test.
- **Traits** that configure a suite or a single test, including ones you write yourself.
- **Typed data sent to the app at launch**, with a small library the app uses to read it.
- **Typed element identifiers** that the app and its tests share, so neither writes them as strings
  and a test does not have to say what kind of element it is looking for.
- **`#expect` and `#require`**, with optional waiting and a diff when a comparison fails.

## Status

This is pre-release software. There is no tagged version yet, and the API may change.

## Requirements

- Swift 6.0 or later (Xcode 16 or later).
- iOS 16, macOS 13, tvOS 16, watchOS 9 or visionOS 1.

The package is built and tested in CI with Xcode 27, and its UI tests run on an iOS
simulator. Other platforms and older versions of Xcode are not tested.

## Installation

Add the package to your project in Xcode, or to `Package.swift`:

```swift
.package(url: "https://github.com/JackMoseley2001/swift-uitesting", branch: "main")
```

It has two libraries:

| Library | Add it to | Contains |
|---|---|---|
| `UITestingCore` | Your app target | What the app needs to read the data a test sends it and to identify its elements. It does not depend on XCTest. |
| `UITesting` | Your UI test target | The macros, traits and runner. It includes `UITestingCore`. |

The package contains macros, so Xcode asks you to trust them the first time you build.
On CI, pass `-skipMacroValidation` to `xcodebuild`.

## Getting started

### 1. Share a payload type

A payload is a `Codable` value that a test sends to the app. Put it in code that is
compiled into both the app and the UI test target: a framework or package they both
link, or a file that is a member of both targets.

```swift
import UITestingCore

struct AuthState: LaunchPayload {
    var isLoggedIn: Bool
    var name: String?
}
```

### 2. Read it in the app

```swift
import UITestingCore

if let auth = LaunchTraits.current[AuthState.self] {
    session.override(isLoggedIn: auth.isLoggedIn, name: auth.name)
}
```

### 3. Write the test

Give the payload a short name in your UI test target, then use it as a trait.

```swift
import UITesting
import XCTest

extension UITestTrait where Self == LaunchPayloadTrait<AuthState> {
    static var loggedOut: Self {
        .launch(AuthState(isLoggedIn: false))
    }

    static func loggedIn(as name: String) -> Self {
        .launch(AuthState(isLoggedIn: true, name: name))
    }
}

@UITestSuite(traits: .loggedIn(as: "Ada"))
final class AccountTests: XCTestCase {
    @UITest
    func showsTheSignedInUser(app: XCUIApplication) {
        #expect(app.staticTexts["user-name"].label == "Ada")
    }
}
```

## Suites and tests

`@UITestSuite` goes on a class that inherits from `XCTestCase`. Its traits apply to
every test in the class.

`@UITest` goes on a method of that class. When the test runs, the app is launched with
the suite's traits and then the test's own, and the method is called.

A test method can:

- take the launched app as an `XCUIApplication`, a `UITestContext`, both, or neither,
  with any parameter names;
- be `async`, throw, both, or neither.

```swift
@UITest
func tapsThrough(in application: XCUIApplication, context: UITestContext) async throws {
    // ...
}
```

Things to know:

- The macro adds a method named `test_` followed by your method's name. That is the
  name XCTest discovers, and the one shown in Xcode and in test reports.
- Do not start the name of a test that takes no parameters with `test`. XCTest would
  also run that method directly, without launching the app. The macro reports this as
  an error and offers to rename it.
- `@UITestSuite` isolates the suite's methods and computed properties to the main
  actor, so tests and their helpers can use elements without writing `@MainActor`:

  ```swift
  @UITestSuite
  final class LoginTests: XCTestCase {
      private func title(in app: XCUIApplication) -> String {
          app[LoginID.title].label
      }

      @UITest
      func showsTheTitle(app: XCUIApplication) {
          #expect(title(in: app) == "Welcome")
      }
  }
  ```

  Overrides such as `setUp()` keep the isolation of what they override, so they
  cannot call these helpers directly. Mark a member `nonisolated` to opt it out.

## Traits

A trait is a reusable piece of configuration or behaviour. These are built in:

| Trait | Effect |
|---|---|
| `.launchArgument("--flag")` | Adds a launch argument. |
| `.launchArguments(["-key", "value"])` | Adds several launch arguments. |
| `.environment("NAME", "value")` | Sets a launch environment variable. |
| `.launch(payload)` | Sends a `LaunchPayload` to the app. |
| `.language("fr")` | Launches the app in a language. |
| `.locale("fr_FR")` | Launches the app in a locale. |
| `.userDefault("key", true)` | Overrides a `UserDefaults` value for the launch. Takes a `Bool`, `Int`, `Double` or `String`. |
| `.orientation(.landscapeLeft)` | Rotates the device for the test, and puts it back afterwards. iOS only. |
| `.systemAlerts(.allow, for: .microphone)` | Answers the system's permission alerts for the test. See [System alerts](#system-alerts). |
| `.resetAuthorization(for: .photos)` | Makes the app forget a permission before it launches, so the system asks again. |
| `.manualLaunch` | Leaves launching the app to the test. See [Launching and relaunching](#launching-and-relaunching). |
| `.actionTimeout(.seconds(10))` | Sets how long actions on elements wait. See [Actions that wait](#actions-that-wait). |
| `.animationsDisabled` | Asks the app to run without animations. The app has to opt in. See [Running without animations](#running-without-animations). |
| `.failureAttachments(false)` | Stops a failed test attaching a screenshot and the element hierarchy. See [When a test fails](#when-a-test-fails). |
| `.enabled(if: condition)` | Skips the test unless the condition is true. |
| `.disabled("reason")` | Skips the test. `.disabled(if:)` skips it when a condition is true. |

Traits are applied in the order they are written, the suite's before the test's, so a
test can override its suite.

### Writing your own

Conform to `UITestTrait`. Every requirement has a default that does nothing, so you
implement only what you need.

```swift
// Configures the launch.
struct SkipOnboarding: UITestTrait {
    func prepare(_ launch: inout LaunchConfiguration) {
        launch.arguments.append("--skip-onboarding")
    }
}

// Does something with the app just before it launches.
struct ForgetPhotosAccess: UITestTrait {
    func willLaunch(_ context: UITestContext) async throws {
        context.app.resetAuthorizationStatus(for: .photos)
    }
}

// Runs code around the test, without sending anything to the app.
struct Landscape: UITestTrait {
    func setUp(_ context: UITestContext) async throws {
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    func tearDown(_ context: UITestContext) async throws {
        XCUIDevice.shared.orientation = .portrait
    }
}
```

| Step | Runs |
|---|---|
| `prepare(_:)` | First, to build the launch arguments and environment. Throw `XCTSkip` here to skip the test. |
| `willLaunch(_:)` | Just before the app is launched, once it has its arguments and environment. |
| `setUp(_:)` | After the app has launched, before the test. With `.manualLaunch`, the app has not launched yet. |
| `tearDown(_:)` | After the test, whether it passed or failed, in reverse order. |

Each step runs for every trait before the next step starts. `tearDown(_:)` is called
for a trait only if its `setUp(_:)` was called, so if a trait fails before that point,
work that another trait did in `willLaunch(_:)` is not undone.

To use a trait with leading-dot syntax, add a static member:

```swift
extension UITestTrait where Self == SkipOnboarding {
    static var skipOnboarding: Self { SkipOnboarding() }
}

@UITest(traits: .skipOnboarding)
func opensTheHomeScreen(app: XCUIApplication) { /* ... */ }
```

## Launching and relaunching

The app is launched before a test starts. A test can launch it again, and it can take
over the first launch.

### Relaunching

`relaunch(with:)` on the test's `UITestContext` ends the app and launches it again. Use
it to check what the app does across a restart:

```swift
@UITest
func keepsTheDraftAcrossARestart(context: UITestContext) throws {
    let app = context.app
    app.textFields["draft-field"].tap()
    app.textFields["draft-field"].typeText("Hello")

    try context.relaunch()

    #expect(app.textFields["draft-field"].value as? String == "Hello")
}
```

Pass traits to launch with a different configuration. They are applied after the
test's own traits, so they can override them:

```swift
try context.relaunch(with: .loggedOut)
```

Things to know:

- Each relaunch starts from the test's traits. Traits passed to one relaunch are not
  carried over to the next.
- Only the `prepare(_:)` step of the traits you pass is used. Their `willLaunch(_:)`,
  `setUp(_:)` and `tearDown(_:)` steps are not run, so a trait such as
  `.orientation(_:)` or `.resetAuthorization(for:)` has no effect here.
- The steps of the test's own traits are not run again either. A permission reset by
  `.resetAuthorization(for:)` stays as the test left it.
- Relaunching does not clear what the app has stored. That is what makes it useful for
  testing a restart.

### Launching the app yourself

With `.manualLaunch`, the app is configured with the test's traits but not launched.
The test does what it needs to first, then launches the app:

```swift
@UITest(traits: .manualLaunch)
func loadsTheFeedFromALocalServer(app: XCUIApplication) async throws {
    // Your own code: something whose details are only known once the test is running.
    let server = try await LocalServer.start()
    app.launchEnvironment["API_URL"] = server.url.absoluteString
    app.launch()

    // ...
}
```

Call `app.launch()` to launch with the test's traits, or `context.relaunch(with:)` to
add more.

The `willLaunch(_:)` and `setUp(_:)` steps of every trait still run before the test,
which means `setUp(_:)` now runs before the app has launched. A trait that looks for
something in the app during `setUp(_:)` does not work with `.manualLaunch`.

If the same work is needed by several tests, write a trait with a `willLaunch(_:)`
step instead.

## Reading launch data in the app

`LaunchTraits.current` gives the app what the test sent:

```swift
let traits = LaunchTraits.current

traits.isUITesting                          // true when a UI test launched the app
traits.hasArgument("--skip-onboarding")     // a launch argument
traits[AuthState.self]                      // a payload, or nil if none was sent
```

In SwiftUI, the same value is in the environment, and previews can override it:

```swift
struct PromoBanner: View {
    @Environment(\.launchTraits) private var launchTraits

    var body: some View {
        if launchTraits.hasArgument("--show-promo-banner") {
            Text("Free delivery this week")
        }
    }
}

#Preview {
    PromoBanner()
        .environment(\.launchTraits, LaunchTraits(arguments: ["--show-promo-banner"]))
}
```

Things to know:

- **Release builds.** `LaunchTraits.current` is always empty in a release build, so a
  shipped app cannot be reconfigured through its environment. If you run UI tests
  against a release build, use `LaunchTraits(processInfo: .processInfo)` instead.
- **Size.** Payloads travel in the launch environment as JSON. Keep them small, and send
  a reference to large data, such as the name of a bundled fixture, not the data itself.
- **Mismatches.** If a payload is present but cannot be decoded, the app stops with an
  assertion failure in a debug build. Use `payload(_:)` to handle the error yourself.

## Running without animations

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

## Element identifiers

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

### Kinds of element

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

### Clashes

The string an element gets is the name of the group, a full stop, and the name of the
member: `LoginID.signInButton` is `"LoginID.signInButton"`. So a `title` in `LoginID` and
a `title` in `SettingsID` are different identifiers, and within one group the compiler
stops two members from sharing a name. A nested type includes the types it is nested
in, so `LoginScreen.ID` and `SettingsScreen.ID` are kept apart too.

### Lists

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

Things to know:

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

## Actions that wait

XCTest's own `tap()` fails at once if the element is not there yet, so tests end up
pairing every action with a wait. An element found by a typed identifier does the
waiting itself:

```swift
@UITest
func deletesAMessage(app: XCUIApplication) throws {
    try app[InboxID.row(1234)].tap()              // waits until it exists and is enabled
    try app[MessageID.deleteButton].tap()
    try app[InboxID.row(1234)].waitToDisappear()
}
```

| Action | Waits until |
|---|---|
| `tap()` | The element exists and is enabled, then taps it. |
| `waitToAppear()` | The element exists. |
| `waitToDisappear()` | The element no longer exists. |

Fields have more. See [Entering text](#entering-text).

### Switches, sliders, steppers and pickers

Identifiers declared as these kinds have actions of their own. Each waits for the
element to exist and be enabled, like `tap()`.

```swift
try app[SettingsID.notificationsSwitch].setOn(true)
try app[PlayerID.volumeSlider].adjust(to: 0.8)
try app[BasketID.quantityStepper].increment(times: 2)
try app[SettingsID.sizePicker].select("Large")
try app[SettingsID.themePicker].select("Dark")
try app[ProfileID.countryPicker].select("France")
```

| Kind | Members | Why not XCTest's own |
|---|---|---|
| `Switch`, `Toggle` | `isOn`, `setOn(_:)`, `toggle()` | `XCUIElement` reports the state as the string `"1"` or `"0"`. `setOn(_:)` does nothing if the switch is already in that state, and checks that it changed. |
| `Slider` | `position`, `adjust(to:tolerance:)` | `adjust(toNormalizedSliderPosition:)` can land several percent away. This drags the thumb, reads where it landed and drags again, until it is within the tolerance, which is 0.02 unless you pass one. |
| `Stepper` | `increment(times:)`, `decrement(times:)` | Finds the two halves of the stepper, which have no identifiers of their own to look up. If the stepper reports a value, each step is checked, so a step past the end of its range fails. Read the value with `value`. |
| `SegmentedControl` | `selection`, `select(_:)` | Finds the segment by its label, and the failure lists the segments if there is none. |
| `MenuPicker` | `selection`, `select(_:)` | For a SwiftUI `Picker` with the `menu` style, or a `Menu`. The options are not inside the control, because the menu is shown over the app. This opens the menu, waits for the option and taps it. The kind matches a button on iOS and a pop-up button on macOS, which is how XCTest reports the control on each. |
| `Picker`, `PickerWheel` (iOS) | `selection()`, `select(_:)` | Finds the wheel inside a picker that has the identifier. Pass `inWheel:` for a picker with several wheels. |

Positions of a slider run from 0 at its start to 1 at its end.

### Scrolling to an element

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

If the element is not ready in time, the failure is recorded at the line of the call
and the test ends, so actions are written with `try`. The message says what went wrong:

```
Could not tap LoginID.signInButton: the button was still disabled after 5 seconds
```

```
Could not tap LoginID.title: no button with this identifier appeared within 5 seconds
An element of type staticText has this identifier. Is the identifier declared as the wrong kind?
```

Actions wait for up to 5 seconds. Change that for a suite or a test with the
`.actionTimeout(_:)` trait, or for one call with `within:`:

```swift
@UITestSuite(traits: .actionTimeout(.seconds(2)))
final class InboxTests: XCTestCase {
    @UITest
    func loadsALongThread(app: XCUIApplication) throws {
        try app[InboxID.row(1234)].tap()
        try app[ThreadID.spinner].waitToDisappear(within: .seconds(30))
    }
}
```

Things to know:

- **Reading does not wait.** `app[id].label`, `exists` and the other properties of
  `XCUIElement` are read straight away. To wait for a value, use
  `#expect(…, within:)`.
- **The rest of `XCUIElement`.** `app[id]` is a `UITestElement`, not an `XCUIElement`.
  Use its `element` property for anything it does not have, such as
  `app[id].element.swipeUp()`.
- **Waits block.** An action blocks while it waits, in an `async` test too, in the same
  way as `waitForExistence(timeout:)`.
- **Elements found by a string.** `app.buttons["save"]` is a plain `XCUIElement`, with
  XCTest's own actions.

## Entering text

Identifiers declared as `TextField`, `SecureTextField`, `SearchField` or `TextView`
have actions for text. Like `tap()`, they wait for the field to exist and be enabled,
and they give the field the keyboard themselves:

```swift
@UITest
func updatesTheProfile(app: XCUIApplication) throws {
    try app[ProfileID.nameField].replaceText(with: "Grace Hopper")
    try app[ProfileID.passwordField].enter("cobol")
    try app[ProfileID.passwordField].submit()

    #expect(app[ProfileID.nameField].text == "Grace Hopper")
}
```

| Member | What it does |
|---|---|
| `enter(_:)` | Taps the field and types. In a field that already holds text, use `replaceText(with:)` to be sure where the text goes. |
| `replaceText(with:)` | Deletes what the field holds, checks it is empty, then types. |
| `clear()` | Deletes what the field holds, and fails if anything is left. |
| `submit()` | Presses the Return key, whatever the keyboard's language. Not on `TextView`, where Return starts a new line. |
| `text` | The text in the field, read without waiting. Empty for an empty field, where `XCUIElement` reports the placeholder. |

Things to know:

- **Secure fields** report a bullet for each character, so `text` cannot be compared
  with what was typed.

## System alerts

An alert that the system shows over the app, such as a request for permission, is not
part of the app, so the app's identifiers cannot find it. `SystemAlert.current` reaches
the one that is showing:

```swift
@UITest(traits: .resetAuthorization(for: .microphone))
func recordsAfterAccessIsAllowed(app: XCUIApplication) throws {
    try app[RecorderID.recordButton].tap()
    try SystemAlert.current.allow()

    #expect(app[RecorderID.status].label == "Recording")
}
```

Its actions wait for an alert to show, as the actions on elements do, and a failure
says what went wrong:

```
Could not tap "Nope" in the system alert "Allow “Demo” to access your microphone?":
the alert has no button with this label. Its buttons are: "Don’t Allow", "Allow"
```

| Call | What it does |
| --- | --- |
| `allow()` | Taps the button that gives the app what it asked for. |
| `deny()` | Taps the button that refuses. |
| `tap("Allow Once")` | Taps the button with this label. |
| `tapButton(at: 0)` | Taps the button at this position. |
| `waitToAppear()`, `waitToDisappear()` | Wait for an alert to show or to go. |
| `isShowing`, `title`, `buttons` | Read the alert without waiting. |

- **`allow()` and `deny()` work in any language, on the alerts that support them.**
  Some alerts mark these two buttons with identifiers, and that is how they are found.
  An alert that does not mark its buttons fails with a list of the buttons it has. On
  iOS 27.2:

  | Alert | `allow()` | `deny()` |
  | --- | --- | --- |
  | Camera, microphone | Yes | Yes |
  | Photos | Yes, as "Allow Full Access" | Yes |
  | Contacts | No. Its other button is "Continue". | Yes |
  | Location, notifications | No. Use the label. | No. Use the label. |
- **Labels are in the language of the device.** The system writes them, and a trait
  such as `.language("fr")` changes the app's language but not the alert's. Labels use
  a typographic apostrophe, as in "Don’t Allow".
- **Pair it with `.resetAuthorization(for:)`.** The system only asks once, so without a
  reset the alert shows on the first run and never again.
- **A failed test does not leave its alert behind.** A permission alert stays on the
  screen after the app that asked has ended. If a test fails while one is showing, and
  the alert marks the button that refuses, it is refused, so that the next test does
  not start underneath it.
- **iOS and iPadOS only.**

### Answering alerts with a trait

The `.systemAlerts(_:for:)` trait answers alerts for a whole test or suite, so that the
test does not have to:

```swift
@UITest(traits: .systemAlerts(.allow, for: .microphone, .camera))
func recordsAVideo(app: XCUIApplication) throws {
    try app[RecorderID.recordButton].tap()

    #expect(app[RecorderID.status].label == "Recording", within: .seconds(5))
}
```

- **It resets the resources it names** before the launch, as `.resetAuthorization(for:)`
  does, so that the system asks again and gets this answer. `.systemAlerts(.allow)`
  without resources answers every alert it can and resets nothing.
- **The answer is `.allow`, `.deny` or `.button("Label")`.** `.allow` and `.deny` work
  on the alerts in the table above. Location and notifications need the label:
  `.systemAlerts(.button("Allow While Using App"), for: .location)`.
- **A test can give several, and can override its suite.** The last trait that is for
  an alert, and whose button the alert has, decides:

  ```swift
  @UITestSuite(traits: .systemAlerts(.allow))
  final class RecorderTests: XCTestCase {
      @UITest(traits: .systemAlerts(.deny, for: .microphone))
      func explainsThatItNeedsTheMicrophone(app: XCUIApplication) throws { /* ... */ }
  }
  ```

- **A trait for the camera, the microphone, photos or contacts answers only those
  alerts.** The alerts for other resources cannot be told apart, so a trait that names
  one of them answers every alert that has its button.
- **When the answer is given.** While an action or expectation of this library waits,
  and when the alert gets in the way of an action on the app. An alert that no trait
  answers is left for the test to answer with `SystemAlert`.
- **Alerts the app presents itself** are part of the app. Give their buttons
  identifiers and look them up in the app as usual.

## Expectations

`#expect` checks a condition. A failure is recorded against the test at the line it
was written on, and the test carries on.

```swift
#expect(app.staticTexts["auth-status"].label == "Signed in")
#expect(!app.buttons["sign-in-button"].exists, "after signing in")
```

Pass `within:` to wait for something that does not happen immediately. The condition is
checked repeatedly until it is true or the timeout passes.

```swift
app.buttons["load-message-button"].tap()
#expect(app.staticTexts["message"].exists, within: .seconds(5))
```

When a comparison with `==` fails, the message shows how the two values differ. Lines
starting with `-` are what was expected, the value on the right of `==`. Lines starting
with `+` are what was found, the value on the left. The message says so itself.

```
Expectation failed: app.staticTexts["auth-status"].label == "Signed in"
(- expected, + actual)
- "Signed in"
+ "Signed out"
```

`#require` is for when the rest of the test depends on the result. It records the
failure and then ends the test. It can also unwrap an optional.

```swift
try #require(app.staticTexts["message"].exists, within: .seconds(5))
let title = try #require(app.staticTexts["title"].value as? String)
```

A condition cannot contain `await`. Await the value first and pass the result.

### Waiting in async tests

How a wait behaves depends on the test it is in:

- **In a test that is not `async`**, the wait blocks between checks, in the same way as
  `waitForExistence(timeout:)`.
- **In an `async` test**, write `await` before the macro. The wait then suspends the
  test between checks, so other work on the main actor can run, and it ends early if
  the test's task is cancelled.

```swift
@UITest
func loadsTheMessage(app: XCUIApplication) async throws {
    app.buttons["load-message-button"].tap()

    await #expect(app.staticTexts["message"].exists, within: .seconds(5))
    try await #require(app.staticTexts["message"].label == "Hello", within: .seconds(5))

    let detail = try await #require(app.staticTexts["detail"].value as? String, within: .seconds(5))
    #expect(detail.hasPrefix("Loaded"))
}
```

Only a call with `within:` needs `await`. Without a timeout, `#expect` and `#require`
are written the same way in every test. Each check of the condition still blocks,
because element queries are synchronous; what is freed is the time between checks.

### In a file that also imports Swift Testing

Swift Testing has macros called `#expect` and `#require` too, so those names are
ambiguous in a file that imports both `Testing` and `UITesting`. UI test files do not
normally import `Testing`. In one that does:

- Use `#UITestingExpect` and `#UITestingRequire`. They are the same macros under names
  of their own, and work with every supported version of Swift.
- From Swift 6.3 you can also write the module name first: `#UITesting::expect(…)`.
  That is the only way to call Swift Testing's macros in such a file:
  `#Testing::expect(…)`.

## Steps

A test can group what it does into named steps. They are optional.

```swift
@UITest
func sendsAMessage(app: XCUIApplication) throws {
    try step("Sign in") {
        try app[LoginID.emailField].enter("ada@example.com")
        try app[LoginID.signInButton].tap()
    }

    try step("Write the message") {
        try app[InboxID.composeButton].tap()
        try app[ComposeID.bodyField].enter("Hello")
    }
}
```

- **Failures say where they happened.** A failure inside a step starts with the step's
  name, and with each name in turn if steps are nested:

  ```
  [Write the message › Add a photo] Could not tap ComposeID.photoButton: no button with this identifier appeared within 5 seconds
  ```

- **Reports read as steps.** In Xcode's test report each step is an activity, and the
  taps and checks made in it are listed inside it.
- **A step returns what its body returns**, so it can hand a value to the rest of
  the test: `let total = try step("Read the total") { app[BasketID.total].label }`.
- **In an `async` test**, write `try await step("…") { … }` around code that awaits.
  XCTest cannot keep an activity open across an `await`, so in the report that step is
  a marker where it starts, with what happens in it listed after the marker. Failures
  still start with the step's name.

## When a test fails

A test that fails has two things attached to it, which Xcode shows in the test report:

- **Screen at failure**: a screenshot.
- **Element hierarchy at failure**: every element the app had, with its type,
  identifier, label and frame. This is where to look when an element could not be
  found.

They are captured once for a test, at its first failure, so they show the app as it
was when things went wrong. Turn them off for a suite or a test with
`.failureAttachments(false)`.

## Without the macros

The macros are a layer over `UITestRunner`, which you can call yourself:

```swift
final class AccountTests: XCTestCase, UITestSuite {
    static var suiteTraits: [any UITestTrait] {
        [.loggedIn(as: "Ada")]
    }

    @MainActor
    func testShowsTheSignedInUser() async throws {
        try await UITestRunner.run(self, traits: [.launchArgument("--skip-onboarding")]) { context in
            XCTAssertEqual(context.app.staticTexts["user-name"].label, "Ada")
        }
    }
}
```

## Demo

`Examples/Demo` is a small SwiftUI app with a UI test target that uses everything
above. The app opens on a list of examples, each with its own screen, and each test
suite opens the app on the screen it tests with a trait such as `.example(.fruitList)`. Open `Examples/Demo/Demo.xcodeproj` in Xcode and run the tests, or run them from
the command line:

```bash
xcodebuild test -project Examples/Demo/Demo.xcodeproj -scheme Demo -destination "platform=iOS Simulator,name=iPhone 17" -skipMacroValidation
```

## Documentation

Every public symbol has a documentation comment, and both libraries have a DocC
catalog. In Xcode, choose Product > Build Documentation.

## Developing the package

Run the package's tests on a Mac with:

```bash
swift test --disable-experimental-prebuilts
```

The flag makes SwiftPM build swift-syntax from source. With the prebuilt swift-syntax it
downloads for macros, the macro test bundle fails to link.

The `UITestingTests` target needs Swift 6.3 or later, because its files import both
`Testing` and `UITesting`. The libraries and the other test targets build with Swift 6.0.

Two workflows run on every pull request: one runs the package's tests, and the other
builds the demo and runs its UI tests on a simulator.
