# ``UITesting``

Write XCTest UI tests that read like Swift Testing, with macros, traits, typed elements and expectations that wait.

## Overview

UITesting runs on top of XCTest's UI testing support. You mark a test case and its
tests with macros, and each test starts with the app launched the way its traits ask.

```swift
import UITesting
import XCTest

@UITestSuite(traits: .loggedIn(as: "Ada"))
final class AccountTests: XCTestCase {
    @UITest
    func showsTheSignedInUser(app: XCUIApplication) {
        #expect(app[AccountID.userName].label == "Ada")
    }

    @UITest(traits: .loggedOut)
    func signsInAgain(app: XCUIApplication) throws {
        try app[AccountID.signInButton].tap()

        #expect(app[AccountID.authStatus].label == "Signed in", within: .seconds(5))
    }
}
```

Link UITesting to your UI test target only. The app itself links UITestingCore, which
UITesting re-exports. UITestingCore is how the app reads what a test sent it and gives
its elements identifiers that tests find them by.

New to the library? Start with the tutorials in <doc:UITestingTutorials>, which build
a first suite and a trait of your own step by step.

### What is in the library

- **Suites and tests.** ``UITestSuite(traits:)`` and ``UITest(traits:)`` generate the
  code that launches the app for each test. See <doc:WritingTests>.
- **Traits.** Reusable configuration for a suite or a test: what the app is launched
  with, the state of the device, and how the test runs. See <doc:Traits>.
- **Typed elements.** A test finds an element by the identifier the app gave it, and
  the actions on it wait for it to be ready. See <doc:FindingElements> and
  <doc:ActingOnElements>.
- **Messages.** A test can send the app a typed message while it runs, to make
  something happen that it cannot do through the user interface. See
  <doc:SendingMessages>.
- **Expectations.** `#expect` and `#require` check the app, can wait, and show how two
  values differ. XCTest's own assertions still work beside them. See
  <doc:Expectations>.

## Topics

### Essentials

- <doc:UITestingTutorials>
- <doc:WritingTests>
- <doc:Expectations>

### Traits

- <doc:Traits>
- <doc:ConfiguringTheLaunch>
- <doc:SkippingTests>
- <doc:WritingTraits>

### Elements

- <doc:FindingElements>
- <doc:ActingOnElements>
- <doc:EnteringText>
- <doc:Controls>
- <doc:ScrollingAndSwiping>
- <doc:TestingAMacApp>
- <doc:TestingAWatchApp>
- <doc:TestingAVisionApp>
- <doc:TestingATVApp>

### Alerts

- <doc:AlertsAndDialogs>
- <doc:SystemAlerts>

### The life of the app

- <doc:LaunchingAndRelaunching>
- <doc:LeavingTheAppAndOpeningLinks>
- <doc:SendingMessages>

### Reading a test and its failures

- <doc:StepsAndFailures>

### Accessibility

- <doc:AccessibilityAudits>
