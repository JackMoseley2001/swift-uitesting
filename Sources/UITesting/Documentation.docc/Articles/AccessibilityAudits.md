# Accessibility audits

Check a screen for accessibility issues, and ignore the ones you know about.

## Overview

XCTest can audit what the app is showing for accessibility issues, such as text with
too little contrast, text that does not grow with Dynamic Type, and elements with no
description. `runAccessibilityAudit()` on the context runs that audit, and records a
failure for each issue it finds:

```swift
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
@UITest
func theSignInScreenIsAccessible(context: UITestContext) throws {
    try context.app[LoginID.signInButton].waitToAppear()

    try context.runAccessibilityAudit()
}
```

The audit looks at the screen as it is when you call it, so wait for the screen you
mean to check first.

Each issue is a failure at the line of the call. It names the element by its
identifier and says what type of issue it is, and the test carries on after it:

```
Accessibility audit: Contrast failed on LoginID.signInButton
Contrast failed for SwiftUI.AccessibilityNode
The type of this issue is .contrast.
```

## Availability

The audit needs iOS 17, macOS 14, tvOS 17, watchOS 10 or visionOS 1. In a test target
that supports an earlier system, mark the test with `@available`, which the method
that `@UITest` generates takes on as well. Marking the suite covers all of its tests:

```swift
@available(iOS 17, *)
@UITestSuite
final class AccessibilityTests: XCTestCase {
    @UITest
    func theSignInScreenIsAccessible(context: UITestContext) throws {
        try context.runAccessibilityAudit()
    }
}
```

## Ignoring issues you know about

To accept an issue, pass a dictionary from the element's identifier to the types of
issue to ignore for it. The rest of the screen is still checked, and so is that
element for the other types:

```swift
try context.runAccessibilityAudit(
    ignoring: [
        LoginID.signInButton: [.contrast],
        LoginID.terms: [.dynamicType, .textClipped],
        InboxID.row: .all
    ]
)
```

- A key is an ``ElementID`` of any kind, or an ``ElementIDFamily``, which stands for
  every element of the family.
- A value is one or more of XCTest's `XCUIAccessibilityAuditType` values, or `.all`.
- An element is matched by its own accessibility identifier. Ignoring an element does
  not ignore the elements inside it, and an issue about an element that has no
  identifier cannot be ignored here.

## Choosing what to look for

To leave a type of issue out for the whole screen, say which types to look for:

```swift
try context.runAccessibilityAudit(for: [.contrast, .dynamicType])
try context.runAccessibilityAudit(for: .all.subtracting(.hitRegion))
```

Things to know:

- The types are XCTest's. `.dynamicType`, `.textClipped` and `.trait` are not on
  macOS, which has `.action` and `.parentChild` instead.
- What the audit finds is up to the system. On the simulators of watchOS, visionOS and
  tvOS it reports no issue for text that an iPhone reports as too faint.
- The call throws only if XCTest could not run the audit. Issues are failures, not errors.

## Topics

### Running an audit

- ``UITestContext/runAccessibilityAudit(for:ignoring:filePath:line:)``

### Ignoring issues

- ``AccessibilityAuditExclusions``
- ``AccessibilityAuditScope``
- ``AccessibilityAuditMatch``
