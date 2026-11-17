# Expectations

Check what the app shows with `#expect` and `#require`, and wait for what does not happen at once.

## Overview

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

## Waiting in async tests

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

## In a file that also imports Swift Testing

Swift Testing has macros called `#expect` and `#require` too, so those names are
ambiguous in a file that imports both `Testing` and `UITesting`. UI test files do not
normally import `Testing`. In one that does:

- Use `#UITestingExpect` and `#UITestingRequire`. They are the same macros under names
  of their own, and work with every supported version of Swift.
- From Swift 6.3 you can also write the module name first: `#UITesting::expect(…)`.
  That is the only way to call Swift Testing's macros in such a file:
  `#Testing::expect(…)`.

## XCTest's own assertions

A suite is still an `XCTestCase`, so `XCTAssertEqual`, `XCTAssertTrue`, `XCTFail` and
the rest of XCTest's assertions work in a test as they always have. A failed one is
recorded against the test, and the test gets its screenshot and element hierarchy all
the same.

`#expect` and `#require` are the ones to reach for, because they can wait for the
app, they show how two values differ, and `#require` ends the test without a second
failure being reported.

## Topics

### Checking a condition

- ``expect(_:_:within:)``
- ``require(_:_:within:)-(Bool,_,_)``
- ``require(_:_:within:)-(Value?,_,_)``

### In a file that also imports Swift Testing

- ``UITestingExpect(_:_:within:)``
- ``UITestingRequire(_:_:within:)-(Bool,_,_)``
- ``UITestingRequire(_:_:within:)-(Value?,_,_)``

### Errors

- ``RequirementFailedError``
