# Entering text

Type into fields, replace and clear what they hold, and read it back.

## Overview

Identifiers declared as `TextField`, `SecureTextField`, `SearchField` or `TextView`
have actions for text. Like `tap()`, they wait for the field to exist and be enabled,
and they give the field the keyboard themselves:

```swift
@UITest
func updatesTheProfile(app: XCUIApplication) throws {
    try app[ProfileID.nameField].replaceText(with: "Grace Hopper")
    try app[ProfileID.passwordField].enter("cobol")
    try app[ProfileID.passwordField].submit()

    #expect(app[ProfileID.nameField].text == "Grace Hopper")
}
```

| Member | What it does |
|---|---|
| `enter(_:)` | Taps the field and types. In a field that already holds text, use `replaceText(with:)` to be sure where the text goes. |
| `replaceText(with:)` | Deletes what the field holds, checks it is empty, then types. |
| `clear()` | Deletes what the field holds, and fails if anything is left. |
| `submit()` | Presses the Return key, whatever the keyboard's language. Not on `TextView`, where Return starts a new line. |
| `text` | The text in the field, read without waiting. Empty for an empty field, where `XCUIElement` reports the placeholder. |

## Things to know

- **Secure fields** report a bullet for each character, so `text` cannot be compared
  with what was typed.

## Topics

### Typing

- ``UITestElement/enter(_:within:filePath:line:)``
- ``UITestElement/replaceText(with:within:filePath:line:)``
- ``UITestElement/clear(within:filePath:line:)``
- ``UITestElement/submit(within:filePath:line:)``

### Reading

- ``UITestElement/text``
