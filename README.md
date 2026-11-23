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
| The demo's UI tests, on an Apple TV simulator | tvOS 18.5, 26.5 and 27.2 |

The latest Xcode of each major version is used, and each version of iOS is tested with
the Xcode of its own year. With Xcode 16.4, which has Swift 6.1, the package's tests
leave out one target that needs Swift 6.3.

iOS 16 and iOS 17 are supported but not tested in CI, because its runners do not have
simulators for them. The demo builds for iOS 16.4, so its UI tests can be run on those
versions from a Mac that has the simulators.

See [Testing a Mac app](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/testingamacapp/),
[Testing a watch app](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/testingawatchapp/),
[Testing a visionOS app](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/testingavisionapp/) and
[Testing a tvOS app](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/testingatvapp/) for what is different there. The features
that are marked as needing iOS 16.4 are not available on iOS 16.0 to 16.3.

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

## Documentation

Everything else is in the [documentation](https://jackmoseley2001.github.io/swift-uitesting/):
each library has a DocC catalog with an article for each topic, and every public symbol
has a documentation comment.

| For | Read |
|---|---|
| Suites, tests and running a test with several arguments | [Writing suites and tests](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/writingtests/) |
| `#expect` and `#require`, waiting, and files that also import Swift Testing | [Expectations](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/expectations/) |
| The built-in traits, fixing the date and choosing where the device is | [Traits](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/traits/) |
| Launch arguments, environment and typed data | [Configuring the launch](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/configuringthelaunch/) |
| Skipping a test, with a reason or a condition | [Skipping tests](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/skippingtests/) |
| Traits of your own | [Writing your own traits](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/writingtraits/) |
| Reading in the app what a test launched it with | [Reading launch data in the app](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitestingcore/readinglaunchdata/) |
| Typed identifiers that the app and its tests share, and identifiers for lists | [Element identifiers](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitestingcore/elementidentifiers/) |
| Finding elements by identifier, or by label where there is none | [Finding elements](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/findingelements/) |
| Actions that wait, the title of a screen and going back | [Acting on elements](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/actingonelements/) |
| Typing, replacing and clearing text | [Entering text](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/enteringtext/) |
| Switches, sliders, steppers, pickers and date pickers | [Controls and date pickers](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/controls/) |
| Scrolling to an element, pull to refresh and swipe actions | [Scrolling and swiping](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/scrollingandswiping/) |
| The app's own alerts and confirmation dialogs | [Alerts and dialogs](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/alertsanddialogs/) |
| Permission alerts from the system, answered in a test or with a trait | [System alerts and permissions](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/systemalerts/) |
| Relaunching, and launching the app yourself | [Launching and relaunching the app](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/launchingandrelaunching/) |
| Sending the app to the background, ending it and opening links | [Leaving the app and opening links](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/leavingtheappandopeninglinks/) |
| Sending the running app a typed message from a test | [Sending messages to the running app](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/sendingmessages/) |
| Receiving those messages in the app | [Receiving messages from a UI test](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitestingcore/receivingmessages/) |
| Running the app without animations | [Running without animations](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitestingcore/runningwithoutanimations/) |
| Named steps, and what a failed test attaches | [Steps and failures](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/stepsandfailures/) |
| What is different in a Mac app | [Testing a Mac app](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/testingamacapp/) |
| What is different in a watch app | [Testing a watch app](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/testingawatchapp/) |
| What is different in a visionOS app | [Testing a visionOS app](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/testingavisionapp/) |
| What is different in a tvOS app | [Testing a tvOS app](https://jackmoseley2001.github.io/swift-uitesting/documentation/uitesting/testingatvapp/) |

There are also tutorials that build a suite step by step: writing your first UI test,
acting on the app and waiting for it, talking to the app during a test, and writing a
custom trait.

To read the documentation with its tutorials and the reference for every symbol,
choose Product > Build Documentation in Xcode. The Documentation workflow builds the
same pages into one website and publishes it to GitHub Pages when `main` changes. The
links above open the articles as they are in this repository, where a link to a symbol
shows as its name.

## Demo

`Examples/Demo` is a small SwiftUI app for iOS, macOS, watchOS, visionOS and tvOS, with
a UI test target that uses every feature of the library. The app opens on a list of examples, each with its own screen, and each test
suite opens the app on the screen it tests with a trait such as `.example(.fruitList)`. Open `Examples/Demo/Demo.xcodeproj` in Xcode and run the tests, or run them from
the command line:

```bash
xcodebuild test -project Examples/Demo/Demo.xcodeproj -scheme Demo -destination "platform=iOS Simulator,name=iPhone 17" -skipMacroValidation
```

The scheme has two test plans. `Demo`, the default, runs one test at a time on one
simulator. `DemoParallel` runs the suites side by side on copies of the simulator that
Xcode makes, which takes less than half the time on a Mac with cores and memory to spare:

```bash
xcodebuild test -project Examples/Demo/Demo.xcodeproj -scheme Demo -destination "platform=iOS Simulator,name=iPhone 17" -skipMacroValidation -testPlan DemoParallel -parallel-testing-worker-count 3
```

Every copy is a simulator of its own, so keep the number of them low: with too many
running at once, each is slow and tests fail on their time limits. Use `DemoParallel`
with a simulator only, because the tests of a Mac app share one pointer and one
keyboard. The workflows use the default plan: each platform already has a runner of its
own there, and a runner has too few cores to run copies of a simulator.

## Developing the package

Run the package's tests on a Mac with:

```bash
swift test --disable-experimental-prebuilts
```

The flag makes SwiftPM build swift-syntax from source. With the prebuilt swift-syntax it
downloads for macros, the macro test bundle fails to link.

The code is checked with [SwiftLint](https://github.com/realm/SwiftLint), with the rules
in `.swiftlint.yml`. Install it with `brew install swiftlint`, and run it from the root of
the repository:

```bash
swiftlint lint --strict
```

`swiftlint lint --fix` corrects what it can itself. The Lint workflow runs the same check
on every pull request.

The `UITestingTests` target needs Swift 6.3 or later, because its files import both
`Testing` and `UITesting`. The libraries and the other test targets build with Swift 6.0.

Three workflows run on every pull request: one runs the package's tests, one builds the
demo and runs its UI tests on a simulator, and one lints the code. A fourth builds the
documentation website and publishes it when `main` changes.

To build that website on a Mac, with both catalogs and a first page that lists the two
libraries and the tutorials:

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

## Licence

This package is released under the MIT licence. See [LICENSE](LICENSE).
