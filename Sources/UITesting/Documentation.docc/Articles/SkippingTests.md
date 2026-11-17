# Skipping tests

Skip a test outright, or depending on a condition, and say why.

## Overview

`.disabled(_:)` skips a test. Xcode and test reports show it as skipped, with the
comment you give:

```swift
@UITest(traits: .disabled("Waiting for the new checkout screen"))
func completesAPurchase(app: XCUIApplication) { /* ... */ }
```

`.enabled(if:_:)` runs a test only if a condition is true, and `.disabled(if:_:)`
skips it if one is:

```swift
@UITest(traits: .enabled(if: ProcessInfo.processInfo.environment["CI"] == nil, "Needs a signed-in device"))
func purchasesAnItem(app: XCUIApplication) { /* ... */ }
```

The condition is evaluated when the test starts, before the app is launched, so a
skipped test costs no launch. On a suite, the trait skips every test in it.

## Skipping from your own trait

These traits skip by throwing `XCTSkip` from their `prepare(_:)` step. A trait of your
own can do the same. See <doc:WritingTraits>.

## Topics

### Traits

- ``UITestTrait/disabled(_:)``
- ``UITestTrait/enabled(if:_:)``
- ``UITestTrait/disabled(if:_:)``
- ``ConditionTrait``
