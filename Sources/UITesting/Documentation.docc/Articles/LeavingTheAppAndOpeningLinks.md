# Leaving the app and opening links

Send the app to the background, bring it back, end it, and open links in it.

## Overview

The context can also send the app to the background, bring it back and end it, to
check what the app does when the user leaves:

```swift
@UITest
func hidesTheBalanceAfterLeavingTheApp(context: UITestContext) throws {
    try context.background()
    context.foreground()

    #expect(context.app[AccountID.balance].label == "Hidden")
}
```

| Call | Effect |
|---|---|
| `try context.background()` | Sends the app to the background, as if the user had gone to the Home Screen, and waits until it is there. iOS only. |
| `context.foreground()` | Brings the app to the foreground. An app that is not running is launched as it was last launched. |
| `context.terminate()` | Ends the app. |

Between `background()` and `foreground()` the app keeps running, with everything it
holds in memory. After `terminate()` it starts from nothing.

## Opening links

`open(_:)` opens a URL in the way the system does when the user taps a link:

```swift
@UITest
func opensAnOrderFromALink(context: UITestContext) {
    context.open(URL(string: "shop://orders/42")!)

    #expect(context.app[OrderID.title].label == "Order 42")
}
```

- If the app is running, in the foreground or the background, it keeps running and
  receives the link.
- If the app is not running, such as after `terminate()`, it is launched with the
  link and with the configuration of its last launch.

To launch the app from nothing with a link, whatever it was doing, use
`relaunch(opening:with:)`. It takes traits in the same way as `relaunch(with:)`:

```swift
try context.relaunch(opening: URL(string: "shop://orders/42")!, with: .loggedOut)
```

Things to know:

- While the app is running, the link goes to whichever app the system chooses for it.
  That is your app for a URL scheme only it declares. A universal link reaches your
  app only if its domain is associated with the app on the device that runs the test;
  otherwise it opens in Safari.
- Both calls need iOS 16.4, macOS 13.3, tvOS 16.4 or watchOS 9.4.

## Topics

### Moving between states

- ``UITestContext/background(within:filePath:line:)``
- ``UITestContext/foreground()``
- ``UITestContext/terminate()``

### Links

- ``UITestContext/open(_:)``
- ``UITestContext/relaunch(opening:with:)``
