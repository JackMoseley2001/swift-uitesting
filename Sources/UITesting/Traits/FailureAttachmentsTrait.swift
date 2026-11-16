/// Sets whether a test that fails has a screenshot and the app's element hierarchy attached.
public struct FailureAttachmentsTrait: UITestTrait {
    /// Whether the attachments are made.
    public let isEnabled: Bool
}

extension UITestTrait where Self == FailureAttachmentsTrait {
    /// Sets whether a test that fails has a screenshot and the app's element hierarchy
    /// attached to it.
    ///
    /// They are attached unless a suite or a test says otherwise, so the only use of
    /// this trait is to turn them off, or back on for one test of a suite that turned
    /// them off:
    ///
    /// ```swift
    /// @UITestSuite(traits: .failureAttachments(false))
    /// final class SmokeTests: XCTestCase { … }
    /// ```
    ///
    /// - Parameter isEnabled: Whether to attach them.
    public static func failureAttachments(_ isEnabled: Bool) -> Self {
        FailureAttachmentsTrait(isEnabled: isEnabled)
    }
}

extension FailureAttachmentsTrait {
    /// Whether the traits ask for attachments on failure. The last trait wins, and
    /// without one they are made.
    static func isEnabled(in traits: [any UITestTrait]) -> Bool {
        traits.compactMap { $0 as? FailureAttachmentsTrait }.last?.isEnabled ?? true
    }
}
