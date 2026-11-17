# Receiving messages from a UI test

Let a UI test make something happen in the app while it is running, such as a session expiring.

## Overview

A ``LaunchPayload`` configures the app once, when it launches. A ``UITestMessage``
reaches it later, in the middle of a test. A test sends one with `context.send(_:)`
from the UITesting library, and carries on when the app has finished handling it.

Declare the message in code that both the app and the UI test target compile:

```swift
import UITestingCore

struct ExpireSession: UITestMessage {}

struct RenameUser: UITestMessage {
    var name: String
}
```

## Receiving a message

In SwiftUI, `onUITestMessage(_:perform:)` receives messages of one type for as long as
the view it is on is on screen. The closure runs on the main actor, and can be `async`
and throw. An error it throws fails the test that sent the message.

Outside SwiftUI, do the same in a task with `UITestMessages.receive(_:perform:)`,
which handles messages until the task is cancelled:

```swift
let receiving = Task {
    await UITestMessages.receive(RenameUser.self) { message in
        try account.rename(to: message.name)
    }
}
```

`UITestMessages.messages(of:)` gives the messages as an `AsyncSequence`, for code that
would sooner loop over them. The test carries on when the loop comes back for the next
message.

```swift
for await message in UITestMessages.messages(of: RenameUser.self) {
    account.rename(to: message.name)
}
```

All three are safe to leave in the app. Nothing is received unless a UI test launched
the app with `.messageChannel`. `onUITestMessage` adds nothing to the view in a release
build, and in a debug build it starts receiving only when a UI test launched the app.

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

### Messages

- ``UITestMessage``

### Receiving

- ``SwiftUICore/View/onUITestMessage(_:perform:)``
- ``UITestMessages``
- ``UITestMessageSequence``
