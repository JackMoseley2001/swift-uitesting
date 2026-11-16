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
- **Typed element identifiers** that the app and its tests share, so neither writes them as strings.
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
- `@UITestSuite` isolates each `@UITest` method to the main actor, so you do not need
  to write `@MainActor`.

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
| `.resetAuthorization(for: .photos)` | Makes the app forget a permission before it launches, so the system asks again. |
| `.manualLaunch` | Leaves launching the app to the test. See [Launching and relaunching](#launching-and-relaunching). |
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

## Element identifiers

A UI test finds an element by its accessibility identifier. Written as strings, the
identifiers have to be kept the same in the app and in the tests by hand, and two
screens can use the same string without anyone noticing.

An `ElementID` is a typed identifier. Declare it in code that both the app and the UI
test target compile, as you do for a payload:

```swift
import UITestingCore

enum LoginID: ElementID {
    case emailField
    case signInButton
}
```

The app tags a view with a case, and a test finds the element with the same case:

```swift
// In the app
Button("Sign in") { signIn() }
    .accessibilityIdentifier(LoginID.signInButton)

// In a UI test
app.buttons[LoginID.signInButton].tap()
```

In a test, `app.buttons[id]` and the other typed queries look for that type of element.
`app[id]` finds the element whatever its type, and `element[id]` looks only inside
another element.

### Clashes

The string an element gets is the name of the identifier's type, a full stop, and the
name of the case: `LoginID.signInButton` is `"LoginID.signInButton"`. So a `title` case
in `LoginID` and a `title` case in `SettingsID` are different identifiers, and within
one enumeration the compiler stops two cases from sharing a name. A nested type
includes the types it is nested in, so `LoginScreen.ID` and `SettingsScreen.ID` are
kept apart too.

### Lists

Give a case an associated value to identify one element out of many:

```swift
enum InboxID: ElementID {
    case list
    case row(Int)
    case deleteButton(row: Int)
}

// In the app
ForEach(messages) { message in
    MessageRow(message)
        .accessibilityIdentifier(InboxID.row(message.id))
}

// In a UI test
app.buttons[InboxID.row(1234)].tap()
```

Things to know:

- **Associated values.** Use simple ones, such as integers, strings and UUIDs. A value
  of one of your own types is described with the name of its module, which is
  different in the app and in the UI test target.
- **Identifiers the app already has.** Give the cases raw string values to choose each
  name, and add `static var namespace: String? { nil }` to drop the prefix. The
  identifier is then exactly the raw value, and avoiding clashes is up to you.
- **Renaming.** The default identifiers follow the names in your code. To keep them
  stable when a type is renamed, give the type its own `namespace`.
- **UIKit and AppKit.** Set the element's identifier to the value's
  `accessibilityIdentifier` string:
  `button.accessibilityIdentifier = LoginID.signInButton.accessibilityIdentifier`.
- **Where the names come from.** A case's name is read at run time, as `print` reads it.
  If the app is built without reflection metadata, or the type is
  `CustomStringConvertible`, give the type its own `name`.

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
above. Open `Examples/Demo/Demo.xcodeproj` in Xcode and run the tests, or run them from
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
