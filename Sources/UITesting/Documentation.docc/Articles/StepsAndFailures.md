# Steps and failures

Name the steps of a test, and see what the app looked like when a test failed.

## Overview

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

## Topics

### Steps

- ``step(_:_:)-(_,()->Result)``

### Attachments

- ``UITestTrait/failureAttachments(_:)``
- ``FailureAttachmentsTrait``
