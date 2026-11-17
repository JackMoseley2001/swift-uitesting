#if canImport(SwiftUI)
import SwiftUI

extension View {
    /// Receives messages of one type from a UI test while the view is on screen.
    ///
    /// ```swift
    /// AccountView()
    ///     .onUITestMessage(ExpireSession.self) { _ in
    ///         session.expire()
    ///     }
    /// ```
    ///
    /// The test that sent the message carries on when `perform` returns, and fails if
    /// `perform` throws.
    ///
    /// The modifier is safe to leave in the app. In a release build it adds nothing to
    /// the view. In a debug build it starts receiving only if a UI test launched the
    /// app, which ``LaunchTraits/isUITesting`` reports, and messages only arrive if
    /// that test has the `messageChannel` trait.
    ///
    /// The closure is the one the view had when it appeared. Have it change state, or
    /// call into a model, and not read values that the view was created with.
    ///
    /// - Parameters:
    ///   - type: The type of message to receive.
    ///   - perform: What to do with a message. It runs on the main actor.
    public func onUITestMessage<Message: UITestMessage>(
        _ type: Message.Type = Message.self,
        perform: @escaping @MainActor (Message) async throws -> Void
    ) -> some View {
        #if DEBUG
            modifier(UITestMessageModifier(perform: perform))
        #else
            self
        #endif
    }
}

#if DEBUG
private struct UITestMessageModifier<Message: UITestMessage>: ViewModifier {
    let perform: @MainActor (Message) async throws -> Void

    func body(content: Content) -> some View {
        if LaunchTraits.current.isUITesting {
            // The task ends when the view goes away, and the messages stop with it.
            content.task {
                await UITestMessages.receive(Message.self, perform: perform)
            }
        } else {
            content
        }
    }
}
#endif
#endif
