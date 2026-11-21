# swift-uitesting

[![Tests](https://github.com/JackMoseley2001/swift-uitesting/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/JackMoseley2001/swift-uitesting/actions/workflows/tests.yml?query=branch%3Amain)
[![Demo UI Tests](https://github.com/JackMoseley2001/swift-uitesting/actions/workflows/demo.yml/badge.svg?branch=main)](https://github.com/JackMoseley2001/swift-uitesting/actions/workflows/demo.yml?query=branch%3Amain)
![Swift 6.0 or later](https://img.shields.io/badge/Swift-6.0%2B-F05138?logo=swift&logoColor=white)
![Xcode 16 or later](https://img.shields.io/badge/Xcode-16%2B-147EFB?logo=xcode&logoColor=white)
![Platforms: iOS 16, macOS 13, tvOS 16, watchOS 9, visionOS 1](https://img.shields.io/badge/platforms-iOS%2016%20%7C%20macOS%2013%20%7C%20tvOS%2016%20%7C%20watchOS%209%20%7C%20visionOS%201-lightgrey)

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
- **Typed messages sent to the app while it runs**, for what a test cannot do through the
  user interface, such as expiring a session.
- **Typed element identifiers** that the app and its tests share, so neither writes them as strings
  and a test does not have to say what kind of element it is looking for.
- **`#expect` and `#require`**, with optional waiting and a diff when a comparison fails.

## Status

This is pre-release software. There is no tagged version yet, and the API may change.

## Requirements

- Swift 6.0 or later (Xcode 16 or later).
- iOS 16, macOS 13, tvOS 16, watchOS 9 or visionOS 1.

CI covers that range on every pull request and on `main`:

| What runs | With |
|---|---|
| The package's tests | Xcode 16.4, 26.6 and 27.2 |
| A build of the libraries for iOS, macOS, tvOS, watchOS and visionOS | Xcode 27.2 |
| The demo's UI tests, on an iPhone simulator | iOS 18.5, 26.5 and 27 |
| The demo's UI tests, as a Mac app | macOS, with Xcode 27.1 |
| The demo's UI tests, on an Apple Watch simulator | watchOS 11.5, 26.5 and 27.2 |
| The demo's UI tests, on an Apple Vision Pro simulator | visionOS 2.5, 26.5 and 27.2 |

The latest Xcode of each major version is used, and each version of iOS is tested with
the Xcode of its own year. With Xcode 16.4, which has Swift 6.1, the package's tests
leave out one target that needs Swift 6.3.

iOS 16 and iOS 17 are supported but not tested in CI, because its runners do not have
simulators for them. The demo builds for iOS 16.4, so its UI tests can be run on those
versions from a Mac that has the simulators.

tvOS is built for but not tested. See [Testing a Mac app](#testing-a-mac-app),
[Testing a watch app](#testing-a-watch-app) and
[Testing a visionOS app](#testing-a-visionos-app) for what is different there. The features
that are marked as needing iOS 16.4 are not available on iOS 16.0 to 16.3.

tvOS has no touch screen, so XCTest has no taps, drags or swipes there. On tvOS the
library has no actions that touch the screen: `tap()`, entering text, scrolling, swipe
actions, changing a control and tapping a button of an alert. Looking elements up,
reading them, waiting for them and expectations all work, as do traits and messages.

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

### Running a test with several arguments

Give `@UITest` a collection of `arguments` to run a test once for each of them. The
method takes one parameter for the argument, as well as the app and the context if it
wants them:

```swift
@UITest(arguments: [Fruit.apple, .pear, .cherry])
func tappingARowSelectsItsFruit(_ fruit: Fruit, app: XCUIApplication) throws {
    try app[FruitID.row(fruit.id)].tap()

    #expect(app[FruitID.selection].label == "Selected \(fruit.name)")
}
```

Each argument gets a run of its own: the app is launched fresh with the test's traits,
and the traits are set up and torn down around it. A failure with one argument does not
stop the others from running.

Things to know:

- XCTest cannot add tests while it is running, so this is one test to XCTest. It is
  shown once in Xcode and in reports, it fails if it fails for any argument, and one
  argument cannot be run on its own.
- Each run is a [step](#steps) named after the parameter and the argument, so a failure
  starts with which argument it was: `[fruit: Pear] Expectation failed: …`. Give the
  type of the argument a `description` that tells the arguments apart.
- A failed test has a screenshot and the element hierarchy for each argument that
  failed.
- The app is launched once for each argument, which takes as long as that many
  separate tests.
- The traits are the same for every argument. To launch the app differently for each
  one, leave the launch to the test:

  ```swift
  @UITest(traits: .manualLaunch, arguments: ["en", "fr", "de"])
  func showsTheTitle(in language: String, context: UITestContext) throws {
      try context.relaunch(with: .language(language))

      #expect(context.app[HomeID.title].exists)
  }
  ```

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
| `.dynamicTypeSize(.accessibility3)` | Launches the app with a Dynamic Type size. The device's setting is not changed. |
| `.timeZone("Asia/Tokyo")` | Launches the app in a time zone. The device's setting is not changed. |
| `.now("2026-03-14T09:30:00Z")` | Asks the app to treat a date as the current one. The app reads it from `LaunchTraits.current.now`. |
| `.orientation(.landscapeLeft)` | Rotates the device for the test, and puts it back afterwards. iOS only. |
| `.location(latitude: 51.5074, longitude: -0.1278)` | Puts the device at a location for the test, and puts it back afterwards. |
| `.systemAlerts(.allow, for: .microphone)` | Answers the system's permission alerts for the test. See [System alerts](#system-alerts). |
| `.resetAuthorization(for: .photos)` | Makes the app forget a permission before it launches, so the system asks again. |
| `.manualLaunch` | Leaves launching the app to the test. See [Launching and relaunching](#launching-and-relaunching). |
| `.messageChannel` | Lets the test send messages to the app while it is running. See [Sending messages to the running app](#sending-messages-to-the-running-app). |
| `.actionTimeout(.seconds(10))` | Sets how long actions on elements wait. See [Actions that wait](#actions-that-wait). |
| `.animationsDisabled` | Asks the app to run without animations. The app has to opt in. See [Running without animations](#running-without-animations). |
| `.failureAttachments(false)` | Stops a failed test attaching a screenshot and the element hierarchy. See [When a test fails](#when-a-test-fails). |
| `.enabled(if: condition)` | Skips the test unless the condition is true. |
| `.disabled("reason")` | Skips the test. `.disabled(if:)` skips it when a condition is true. |

Traits are applied in the order they are written, the suite's before the test's, so a
test can override its suite.

### Fixing the date

XCTest cannot change the clock of the device, so `.now(_:)` sends a date to the app
and the app reads it. `LaunchTraits.current.now`, from UITestingCore, is the date of
the test, or the date on the clock when no test fixed one:

```swift
// In the app, wherever it would create a Date()
let isOverdue = task.dueDate < LaunchTraits.current.now
```

```swift
@UITest(traits: .now("2026-03-14T09:30:00Z"), .timeZone("Europe/London"))
func showsTheTaskAsOverdue(app: XCUIApplication) {
    #expect(app[TaskID.status].label == "Overdue")
}
```

The date is written in ISO 8601 format and has to say which time zone it is in, with
`Z` or an offset such as `+09:00`. `.now(_:)` takes a `Date` as well. The date does
not move while the app runs. Which day it is depends on the time zone of the app, so
a test of dates usually gives `.timeZone(_:)` too.

### Choosing where the device is

`.location(latitude:longitude:)` puts the device at a location before the app is
launched, and puts the previous one back when the test finishes. This is the
location that the system reports, so the app gets it
from Core Location with no extra code.

```swift
@UITest(
    traits: .location(latitude: 51.5074, longitude: -0.1278),
    .systemAlerts(.button("Allow While Using App"), for: .location)
)
func showsTheNearestShop(app: XCUIApplication) throws {
    try app[ShopsID.findButton].tap()

    #expect(app[ShopsID.nearest].label == "Covent Garden", within: .seconds(10))
}
```

The app still needs permission to read the location. See [System alerts](#system-alerts)
for answering the alert. The trait needs iOS 16.4, macOS 13.3, tvOS 16.4 or watchOS 9.4.

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
for every trait whose `willLaunch(_:)` was called. If a trait's `willLaunch(_:)`
throws, the app is not launched and no trait is set up, but that trait and the ones
before it are still torn down, so what they did before the launch can be undone.

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

### Leaving the app and coming back

The context can also send the app to the background, bring it back and end it, to
check what the app does when the user leaves:

```swift
@UITest
func hidesTheBalanceAfterLeavingTheApp(context: UITestContext) throws {
    try context.background()
    context.foreground()

    #expect(context.app[AccountID.balance].label == "Hidden")
}
```

| Call | Effect |
|---|---|
| `try context.background()` | Sends the app to the background, as if the user had gone to the Home Screen, and waits until it is there. iOS only. |
| `context.foreground()` | Brings the app to the foreground. An app that is not running is launched as it was last launched. |
| `context.terminate()` | Ends the app. |

Between `background()` and `foreground()` the app keeps running, with everything it
holds in memory. After `terminate()` it starts from nothing.

### Opening links

`open(_:)` opens a URL in the way the system does when the user taps a link:

```swift
@UITest
func opensAnOrderFromALink(context: UITestContext) {
    context.open(URL(string: "shop://orders/42")!)

    #expect(context.app[OrderID.title].label == "Order 42")
}
```

- If the app is running, in the foreground or the background, it keeps running and
  receives the link.
- If the app is not running, such as after `terminate()`, it is launched with the
  link and with the configuration of its last launch.

To launch the app from nothing with a link, whatever it was doing, use
`relaunch(opening:with:)`. It takes traits in the same way as `relaunch(with:)`:

```swift
try context.relaunch(opening: URL(string: "shop://orders/42")!, with: .loggedOut)
```

Things to know:

- While the app is running, the link goes to whichever app the system chooses for it.
  That is your app for a URL scheme only it declares. A universal link reaches your
  app only if its domain is associated with the app on the device that runs the test;
  otherwise it opens in Safari.
- Both calls need iOS 16.4, macOS 13.3, tvOS 16.4 or watchOS 9.4.

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

## Sending messages to the running app

A payload configures the app once, when it launches. A message reaches it later, in the
middle of a test, to make something happen that the test cannot do through the user
interface: a session that expires, a notification that arrives, a clock that moves on.

A message is a `Codable` type that the app and the UI test target both compile, as a
payload is:

```swift
import UITestingCore

struct ExpireSession: UITestMessage {}
```

The app says what to do when one arrives:

```swift
AccountView()
    .onUITestMessage(ExpireSession.self) { _ in
        session.expire()
    }
```

And a test that has the `.messageChannel` trait sends it:

```swift
@UITest(traits: .loggedIn(as: "Ada"), .messageChannel)
func signsOutWhenTheSessionExpires(context: UITestContext) throws {
    try context.send(ExpireSession())

    #expect(context.app[AccountID.authStatus].label == "Signed out")
}
```

### Sending from a test

`send(_:)` is on the test's `UITestContext`. It returns when the app has finished
handling the message, so the next line can check what the app shows.

- **It waits for the app to be ready**, as actions on elements do. An app that has only
  just launched, or a screen that is still on its way in, may not be receiving the
  message yet, so `send(_:)` tries again until it is. That makes it safe as the first
  line of a test, and after `relaunch(with:)`.
- **It waits for up to 5 seconds**, or for the time set with `.actionTimeout(_:)`, or
  for one call with `within:`:
  `try context.send(ImportLibrary(), within: .seconds(30))`.
- **A failure says what went wrong**, is recorded at the line of the call, and ends the
  test:

  ```
  Could not send ExpireSession: nothing in the app was receiving this message after 5 seconds
  ```

  ```
  The app failed to handle RenameUser: nameTooLong
  ```

- **A message can carry values.** Give the type properties, and the app receives them:

  ```swift
  struct RenameUser: UITestMessage {
      var name: String
  }

  try context.send(RenameUser(name: "Grace"))
  ```

### Receiving in the app

In SwiftUI, `onUITestMessage(_:perform:)` receives messages of one type for as long as
the view it is on is on screen. The closure runs on the main actor, and can be `async`
and throw. An error it throws fails the test that sent the message.

Outside SwiftUI, do the same in a task with `UITestMessages.receive(_:perform:)`,
which handles messages until the task is cancelled:

```swift
let receiving = Task {
    await UITestMessages.receive(RenameUser.self) { message in
        try account.rename(to: message.name)
    }
}
```

`UITestMessages.messages(of:)` gives the messages as an `AsyncSequence`, for code that
would sooner loop over them. The test carries on when the loop comes back for the next
message.

```swift
for await message in UITestMessages.messages(of: RenameUser.self) {
    account.rename(to: message.name)
}
```

All three are safe to leave in the app. Nothing is received unless a UI test launched
the app with `.messageChannel`. `onUITestMessage` adds nothing to the view in a release
build, and in a debug build it starts receiving only when a UI test launched the app.

Things to know:

- **Release builds.** The app finds the test through `LaunchTraits.current`, which is
  always empty in a release build. A shipped app never listens for messages, and a UI
  test cannot send them to a release build.
- **The view has to be on screen.** A view's `onUITestMessage` stops receiving when the
  view goes away. Put it on a view that is there for as long as tests need it, such as
  the root view for something the whole app reacts to.
- **Several receivers.** If more than one place receives the same type of message, each
  gets it, in the order they started receiving.
- **Messages go one way.** A message makes something happen in the app. It cannot
  return a value to the test, which reads the result from the app's elements.
- **How it travels.** The test listens on a port of the device's loopback interface,
  which nothing outside the device can reach, and launches the app with the port in
  its environment. The app connects the first time it asks to receive a message. The
  channel lasts for one test and is closed when the test is torn down.
- **Messages are JSON.** Keep them small, as you do payloads.
- **An app that ends while handling a message** has not answered it, so `send(_:)`
  keeps waiting, and sends the message again if the app is launched again in time.
- **Platforms.** It is tested on the iOS simulator.

## Reading launch data in the app

`LaunchTraits.current` gives the app what the test sent:

```swift
let traits = LaunchTraits.current

traits.isUITesting                          // true when a UI test launched the app
traits.hasArgument("--skip-onboarding")     // a launch argument
traits[AuthState.self]                      // a payload, or nil if none was sent
traits.now                                  // the date the test fixed, or the date on the clock
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

An element that the app cannot tag, such as one in a web view, is found by its label.
See [Elements without an identifier](#elements-without-an-identifier).

### Kinds of element

Inside a group, `Button`, `StaticText`, `TextField` and the rest are types of
identifier, one for each element type that XCTest reports. Some common ones:

| Kind | Matches |
|---|---|
| `Button` | Buttons, including a SwiftUI `NavigationLink`. |
| `StaticText` | Text the user cannot edit: a SwiftUI `Text`, a `UILabel`. |
| `TextField`, `SecureTextField`, `TextView` | A text field, a password field, and a multi-line editor. |
| `Switch`, `CheckBox` | A SwiftUI `Toggle` is a `Switch` on iOS and a `CheckBox` on macOS. |
| `Slider`, `Stepper`, `Picker`, `DatePicker`, `SegmentedControl`, `SegmentedPicker`, `MenuPicker` | Controls. A SwiftUI `Picker` is a different kind for each picker style: `Picker` for a wheel, `SegmentedPicker` for segments, and `MenuPicker` for a menu. `SegmentedPicker` and `MenuPicker` match what XCTest reports on iOS and on macOS, which differ. |
| `Image`, `Link`, `Cell`, `Table`, `CollectionView`, `Outline`, `List`, `ScrollView` | Content and containers. A SwiftUI `List` is a `CollectionView` on recent versions of iOS and an `Outline` on macOS, and `List` matches whichever it is. |
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

Things to know:

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

### The title of a screen, and going back

A screen in a navigation stack has a title and a button to go back, and neither has
an identifier of the app's. The app has both:

```swift
@UITest
func opensAMessageAndGoesBack(app: XCUIApplication) throws {
    try app[InboxID.row(1234)].tap()
    #expect(app.navigationTitle == "Message", within: .seconds(2))

    try app.goBack()
    #expect(app.navigationTitle == "Inbox", within: .seconds(2))
}
```

`navigationTitle` is the title of the screen that is showing, read without waiting, and
is empty if there is none. `goBack()` waits for the button to go back and taps it. The
label of that button is in the language of the app, and on iOS it is the title of the
screen before, so `goBack()` finds it by what the system calls it, which is the same in
every language.

Both work on iOS and on macOS, where the title is in the title bar of the window and
the button is in its toolbar.

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
| `Switch`, `Toggle`, `CheckBox` | `isOn`, `setOn(_:)`, `toggle()` | `XCUIElement` reports the state as the string `"1"` or `"0"`. `setOn(_:)` does nothing if the switch is already in that state, and checks that it changed. |
| `Slider` | `position`, `adjust(to:tolerance:)` | `adjust(toNormalizedSliderPosition:)` can land several percent away. This drags the thumb, reads where it landed and drags again, until it is within the tolerance, which is 0.02 unless you pass one. |
| `Stepper` | `value`, `increment(times:)`, `decrement(times:)` | Finds the two halves of the stepper, which have no identifiers of their own to look up. If the stepper reports a value, each step is checked, so a step past the end of its range fails. Pass `requiringChange: false` when a step is allowed to change nothing. `value` is the stepper's value as text, which `XCUIElement` reports as a string on iOS and as a number on macOS. |
| `SegmentedControl`, `SegmentedPicker`, `RadioGroup` | `selection`, `select(_:)` | Finds the segment by its label, and the failure lists the segments if there is none. `SegmentedPicker` is a SwiftUI `Picker` with the `segmented` style, which is a segmented control on iOS and a group of radio buttons on macOS. |
| `MenuPicker` | `selection`, `select(_:)` | For a SwiftUI `Picker` with the `menu` style, or a `Menu`. The options are not inside the control, because the menu is shown over the app. This opens the menu, waits for the option and taps it. The kind matches a button on iOS and a pop-up button on macOS, which is how XCTest reports the control on each. |
| `Picker`, `PickerWheel` (iOS) | `selection()`, `select(_:)` | Finds the wheel inside a picker that has the identifier. Pass `inWheel:` for a picker with several wheels. |

Positions of a slider run from 0 at its start to 1 at its end.

### Date pickers

Identifiers declared as `DatePicker` can be set to a date or a time, on iOS:

```swift
try app[BookingID.datePicker].setDate(year: 2026, month: 3, day: 9)
try app[BookingID.timePicker].setTime(hour: 14, minute: 30)
```

A date picker is several controls, and which ones depends on its style. These actions
open the calendar or the wheels if they have to, set them, check where they ended up
and close them again.

| Style | `setDate` | `setTime` |
|---|---|---|
| `compact`, the default | Yes | Yes |
| `graphical` | Yes | No |
| `wheel` | Yes | Yes |

- **The hour is from 0 to 23**, whether or not the picker shows AM and PM.
- **The month and AM or PM are found by name**, in the language of the device. If the
  test launches the app in another language, pass it:
  `setDate(year: 2026, month: 3, day: 9, locale: Locale(identifier: "fr"))`.
- **A date outside the picker's range** fails, because its day cannot be selected.
- **A `wheel` picker that shows a date and a time** has one wheel for the day, such as
  "Tue, Nov 14", in place of a month, a day and a year. `setDate` turns it in steps of
  up to 45 days, so the app is given each date on the way to one that is further off.
  The wheel shows no year, so the picker is taken to be on the nearest date to the
  one asked for that reads the same. That is right for a date within two years of the
  picker's own. XCTest can only turn this wheel when the app runs in the language and
  region of the device, so not in a test that uses `.locale(_:)` or `.language(_:)`.

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

### Pull to refresh

```swift
try app[InboxID.list].pullToRefresh()
#expect(app[InboxID.row(1234)].exists, within: .seconds(5))
```

`pullToRefresh` waits for the list or scroll view, and drags it down from near its top.

- **It returns when the drag is done, not when the refresh is.** Wait for what the
  refresh brings with an expectation that has a timeout.
- **The content has to be at its top.** Otherwise the drag scrolls the content back up,
  as it does for a person.

### Swipe actions on a row

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

The result is the same type of element that `app[id]` gives, so its actions wait, and
a failure says what was looked for:

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
  `label`, and `scrollIntoView()` fail with XCTest's own message about multiple
  matching elements.
- **No identifier.** The `accessibilityIdentifier` of an element found by its label is
  an empty string.

## Alerts and dialogs

SwiftUI gives no way to put an identifier on an alert or a confirmation dialog, so they
are reached through the app:

```swift
try app[DraftID.deleteButton].tap()

#expect(app.alert.title == "Delete the draft?")
try app.alert.tap("Delete")
```

`app.alert` is the alert that is showing. `app.dialog` is the confirmation dialog or
action sheet. Their actions wait for it to show, and a failed tap lists the buttons
there are:

```
Could not tap "Remove" in the alert "Delete the draft?": the alert has no button with
this label. Its buttons are: "Cancel", "Delete"
```

| Member | What it does |
| --- | --- |
| `tap("Delete")` | Taps the button with this label. |
| `tapButton(at: 0)` | Taps the button at this position. |
| `app.alert[DraftID.confirmDeleteButton]` | The button with an identifier, which does not depend on the language of the app. |
| `dismiss()` | Closes a dialog by a tap outside it. |
| `waitToAppear()`, `waitToDisappear()` | Wait for it to show or to go. |
| `isShowing`, `title`, `message`, `buttons` | Read it without waiting. |

- **Look identifiers up in the alert, not in the app.** XCTest reports a button of an
  alert twice, one inside the other, so `app[DraftID.confirmDeleteButton]` finds two
  elements and fails.
- **A dialog shown as a popover has no cancel button.** iOS 27 shows a confirmation
  dialog this way on an iPhone, and leaves out the button with the `cancel` role. Use
  `dismiss()`, which runs that button's action.
- **Sheets have nothing of their own.** The content of a `sheet` is ordinary elements
  with no container around them, so look them up in the app as usual.

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

A suite is still an `XCTestCase`, so XCTest's own assertions, such as `XCTAssertEqual`
and `XCTFail`, work in a test as they always have. `#expect` and `#require` are the
ones to reach for, because they can wait, and they show how two values differ.

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
            #expect(context.app.staticTexts["user-name"].label == "Ada")
        }
    }
}
```

## Testing a Mac app

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

### Messages need an entitlement

Xcode runs the UI tests of a Mac app in a sandbox, which does not let them listen for
the app to connect. A test with the `.messageChannel` trait fails with "Operation not
permitted" unless the UI test target has an entitlements file with:

```xml
<key>com.apple.security.network.server</key>
<true/>
```

Set it as the target's Code Signing Entitlements. An app that is sandboxed itself
needs `com.apple.security.network.client` to connect to the test.

### Running the tests

UI tests of a Mac app use the pointer and the keyboard of the Mac they run on, so
leave it alone while they run.

```bash
xcodebuild test -project Examples/Demo/Demo.xcodeproj -scheme Demo -destination "platform=macOS" -skipMacroValidation
```

runs the demo's UI tests against the demo as a Mac app.

## Testing a watch app

A UI test target for a watch app uses the library in the same way, and a test that is
shared with an iOS app reads the same on both. XCTest reports a watch app differently
from an iOS one, and the library takes up the differences:

| In an iOS app | In a watch app | What the library does |
|---|---|---|
| A field is typed into where it is. | A tap on a field opens a screen with a keyboard, and the field has the text when that screen is closed. | `enter(_:)`, `replaceText(with:)` and `clear()` type on that screen and close it with its button for done. |
| Return submits a field. | A field is submitted whenever the screen to type on is closed. | `submit()` opens that screen and closes it. Every action that types submits the field as well. |
| An alert is an alert, and a confirmation dialog is a sheet. | Both are a screen with a table, with the title as the first text inside. | `app.alert` and `app.dialog` both find it, and `title`, `message` and `buttons` read it. |
| The button that cancels a dialog is one of its buttons. | It is a button to close the dialog, in the bar above it. | `app.dialog.dismiss()` taps it. |
| A stepper is a stepper. | It is the text of its label, with a button for each direction inside. | The kind `Stepper` matches an element of any type on watchOS, and `value`, `increment()` and `decrement()` work on it. |
| A slider has a thumb that is dragged. | A slider moves by a step at a time, with a tap on either end. | `adjust(to:)` taps until the slider is there, and fails if the position is between two steps. |
| A drag moves the content by its own length. | The content carries on for several times the length of a drag. | `scrollIntoView()` drags slowly, so that no row goes past unseen. |

A swipe of `scrollIntoView()` moves the content by about half the height of the screen,
which on a watch is less than two rows of a list. Pass a larger `maximumSwipes` for an
element that is far down:

```swift
try app[NumberID.row(60)].scrollIntoView(maximumSwipes: 60)
```

A slider with no `step` moves by a sixth of its range at a time on watchOS, so
`adjust(to: 0.83)` can be reached and `adjust(to: 0.8)` cannot.

Some things are not in a watch app, or are not reported by XCTest on watchOS, and the
library does not have them there: pull to refresh, picker wheels, the actions for date
pickers, `SystemAlert` and the `.systemAlerts` trait, the `.orientation` trait and
`context.background()`. watchOS has no pickers with segments or with a menu, and no
editor for several lines of text. It does not report the identifier of a button of an
alert, so tap such a button by its label.

`context.open(_:)` opens a link in an app that is running, as on iOS. An app that is
not running is launched by the link without the arguments and environment of the
test, so its launch traits do not apply. Launch the app first.

```bash
xcodebuild test -project Examples/Demo/Demo.xcodeproj -scheme Demo \
  -destination "platform=watchOS Simulator,name=Apple Watch Series 12 (46mm)" -skipMacroValidation
```

runs the demo's UI tests against the demo as a watch app.

## Testing a visionOS app

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

```bash
xcodebuild test -project Examples/Demo/Demo.xcodeproj -scheme Demo \
  -destination "platform=visionOS Simulator,name=Apple Vision Pro" -skipMacroValidation
```

runs the demo's UI tests against the demo as a visionOS app.

## Demo

`Examples/Demo` is a small SwiftUI app for iOS and macOS, with a UI test target that
uses everything above. The app opens on a list of examples, each with its own screen, and each test
suite opens the app on the screen it tests with a trait such as `.example(.fruitList)`. Open `Examples/Demo/Demo.xcodeproj` in Xcode and run the tests, or run them from
the command line:

```bash
xcodebuild test -project Examples/Demo/Demo.xcodeproj -scheme Demo -destination "platform=iOS Simulator,name=iPhone 17" -skipMacroValidation
```

## Documentation

Every public symbol has a documentation comment, and both libraries have a DocC
catalog. In Xcode, choose Product > Build Documentation. The catalogs have:

- **Articles**, one for each topic in this README, such as writing tests, traits,
  entering text, alerts and system alerts.
- **Tutorials** that build a suite step by step: writing your first UI test, acting on
  the app and waiting for it, talking to the app during a test, and writing a custom
  trait.

The Documentation workflow builds both catalogs into one website, with a first page
that lists the two libraries and the tutorials, and publishes it to GitHub Pages when
`main` changes. To build the same site on a Mac:

```bash
scripts/build-docs.sh
```

The site is written to `.build/documentation/site`. It expects to be served under
`/swift-uitesting`, as it is on GitHub Pages. For a copy to look at locally, build it
for the root of a server and serve it:

```bash
HOSTING_BASE_PATH="" scripts/build-docs.sh
```

```bash
python3 -m http.server --directory .build/documentation/site
```

Then open `http://localhost:8000/`.

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
builds the demo and runs its UI tests on a simulator. A third builds the documentation
website and publishes it when `main` changes.
