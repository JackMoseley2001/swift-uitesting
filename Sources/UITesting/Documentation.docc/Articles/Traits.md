# Traits

Configure a suite or a single test with reusable pieces of configuration and behaviour.

## Overview

A trait is passed to ``UITestSuite(traits:)`` to apply to every test in a suite, or
to ``UITest(traits:)`` to apply to one test:

```swift
@UITestSuite(traits: .loggedIn(as: "Ada"), .animationsDisabled)
final class AccountTests: XCTestCase {
    @UITest(traits: .language("fr"))
    func showsTheAccountInFrench(app: XCUIApplication) { /* ... */ }
}
```

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
| `.systemAlerts(.allow, for: .microphone)` | Answers the system's permission alerts for the test. See <doc:SystemAlerts>. |
| `.resetAuthorization(for: .photos)` | Makes the app forget a permission before it launches, so the system asks again. |
| `.manualLaunch` | Leaves launching the app to the test. See <doc:LaunchingAndRelaunching>. |
| `.messageChannel` | Lets the test send messages to the app while it is running. See <doc:SendingMessages>. |
| `.actionTimeout(.seconds(10))` | Sets how long actions on elements wait. See <doc:ActingOnElements>. |
| `.animationsDisabled` | Asks the app to run without animations. The app has to opt in, with `uiTestAnimationsDisabled()` from UITestingCore. |
| `.failureAttachments(false)` | Stops a failed test attaching a screenshot and the element hierarchy. See <doc:StepsAndFailures>. |
| `.enabled(if: condition)` | Skips the test unless the condition is true. |
| `.disabled("reason")` | Skips the test. `.disabled(if:)` skips it when a condition is true. |

Traits are applied in the order they are written, the suite's before the test's, so a
test can override its suite.

Each group of traits has an article of its own:

- <doc:ConfiguringTheLaunch> covers arguments, environment variables, payloads,
  language, locale, text size, `UserDefaults`, the time zone, the date and the
  location of the device.
- <doc:SkippingTests> covers `.enabled(if:_:)` and `.disabled(_:)`.
- <doc:SystemAlerts> covers `.systemAlerts(_:for:)` and `.resetAuthorization(for:)`.
- <doc:LaunchingAndRelaunching> covers `.manualLaunch`.
- <doc:SendingMessages> covers `.messageChannel`.
- <doc:WritingTraits> shows how to write your own.

## Topics

### Writing traits

- <doc:WritingTraits>
- ``UITestTrait``

### Configuring the launch

- <doc:ConfiguringTheLaunch>
- ``LaunchArgumentsTrait``
- ``LaunchEnvironmentTrait``
- ``LaunchPayloadTrait``
- ``TimeZoneTrait``
- ``NowTrait``
- ``ManualLaunchTrait``

### Changing the device and its permissions

- ``OrientationTrait``
- ``LocationTrait``
- ``ResetAuthorizationTrait``
- ``SystemAlertsTrait``

### Changing how a test runs

- <doc:SkippingTests>
- ``ConditionTrait``
- ``MessageChannelTrait``
- ``ActionTimeoutTrait``
- ``AnimationsDisabledTrait``
- ``FailureAttachmentsTrait``
