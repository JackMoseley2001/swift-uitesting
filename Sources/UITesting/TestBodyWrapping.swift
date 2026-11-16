/// A trait that takes over running the test body, so that it can do work around it or
/// decide how it runs.
protocol TestBodyWrapping: UITestTrait {
    /// Runs the test body.
    ///
    /// - Parameters:
    ///   - body: The test body, or the body as wrapped by the traits listed after this one.
    ///   - recordFailure: Records a failure of the test with the given message.
    @MainActor
    func run(
        _ body: @escaping @MainActor () async throws -> Void,
        recordFailure: @MainActor (String) -> Void
    ) async throws
}
