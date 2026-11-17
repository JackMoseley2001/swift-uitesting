# Writing suites and tests

Mark a test case and its methods with macros, and each test starts with the app launched for it.

## Overview

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
- Each run is a step (see <doc:StepsAndFailures>) named after the parameter and the argument, so a failure
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

## Checking the app

Check what the app shows with `#expect` and `#require`, which <doc:Expectations>
describes. XCTest's own assertions, such as `XCTAssertEqual`, work in a test too.

## Running a test without the macros

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

## Topics

### Declaring suites and tests

- ``UITestSuite(traits:)``
- ``UITest(traits:)``
- ``UITest(traits:arguments:)``

### Running a test

- ``UITestRunner``
- ``UITestSuite``
- ``UITestContext``
