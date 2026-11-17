# Launching and relaunching the app

Launch the app again in the middle of a test, or take over the first launch.

## Overview

The app is launched before a test starts. A test can launch it again, and it can take
over the first launch.

## Relaunching

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

## Launching the app yourself

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

## Topics

### Launching

- ``UITestContext/relaunch(with:)``
- ``UITestContext/relaunch(opening:with:)``
- ``UITestTrait/manualLaunch``
- ``ManualLaunchTrait``
