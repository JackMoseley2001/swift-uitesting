# Sending messages to the running app

Make something happen in the app in the middle of a test, such as a session expiring, by sending it a typed message.

## Overview

A payload configures the app once, when it launches. A message reaches it later, in the
middle of a test, to make something happen that the test cannot do through the user
interface: a session that expires, a notification that arrives, a clock that moves on.

A message is a `Codable` type that the app and the UI test target both compile, as a
payload is:

```swift
import UITestingCore

struct ExpireSession: UITestMessage {}
```

The app says what to do when one arrives:

```swift
AccountView()
    .onUITestMessage(ExpireSession.self) { _ in
        session.expire()
    }
```

And a test that has the `.messageChannel` trait sends it:

```swift
@UITest(traits: .loggedIn(as: "Ada"), .messageChannel)
func signsOutWhenTheSessionExpires(context: UITestContext) throws {
    try context.send(ExpireSession())

    #expect(context.app[AccountID.authStatus].label == "Signed out")
}
```

For a walk through both sides, see <doc:TalkingToTheApp>.

## Sending from a test

`send(_:)` is on the test's `UITestContext`. It returns when the app has finished
handling the message, so the next line can check what the app shows.

- **It waits for the app to be ready**, as actions on elements do. An app that has only
  just launched, or a screen that is still on its way in, may not be receiving the
  message yet, so `send(_:)` tries again until it is. That makes it safe as the first
  line of a test, and after `relaunch(with:)`.
- **It waits for up to 5 seconds**, or for the time set with `.actionTimeout(_:)`, or
  for one call with `within:`:
  `try context.send(ImportLibrary(), within: .seconds(30))`.
- **A failure says what went wrong**, is recorded at the line of the call, and ends the
  test:

  ```
  Could not send ExpireSession: nothing in the app was receiving this message after 5 seconds
  ```

  ```
  The app failed to handle RenameUser: nameTooLong
  ```

- **A message can carry values.** Give the type properties, and the app receives them:

  ```swift
  struct RenameUser: UITestMessage {
      var name: String
  }

  try context.send(RenameUser(name: "Grace"))
  ```

## Receiving in the app

The app receives a message with `onUITestMessage(_:perform:)` in SwiftUI, or with
`UITestMessages` anywhere else. Both are in UITestingCore, whose documentation
describes them. They do nothing unless a UI test launched the app with
`.messageChannel`, so they are safe to leave in the app.

## Things to know

- **Release builds.** The app finds the test through `LaunchTraits.current`, which is
  always empty in a release build. A shipped app never listens for messages, and a UI
  test cannot send them to a release build.
- **The view has to be on screen.** A view's `onUITestMessage` stops receiving when the
  view goes away. Put it on a view that is there for as long as tests need it, such as
  the root view for something the whole app reacts to.
- **Several receivers.** If more than one place receives the same type of message, each
  gets it, in the order they started receiving.
- **Messages go one way.** A message makes something happen in the app. It cannot
  return a value to the test, which reads the result from the app's elements.
- **How it travels.** The test listens on a port of the device's loopback interface,
  which nothing outside the device can reach, and launches the app with the port in
  its environment. The app connects the first time it asks to receive a message. The
  channel lasts for one test and is closed when the test is torn down.
- **Messages are JSON.** Keep them small, as you do payloads.
- **An app that ends while handling a message** has not answered it, so `send(_:)`
  keeps waiting, and sends the message again if the app is launched again in time.
- **Platforms.** It is tested on the iOS simulator.

## Topics

### Sending

- ``UITestContext/send(_:within:filePath:line:)``
- ``UITestTrait/messageChannel``
- ``MessageChannelTrait``
