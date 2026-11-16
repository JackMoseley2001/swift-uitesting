/// The time limit of the test that is running, which waits consult so that they do not
/// outlast it.
struct TestTimeLimit: Sendable {
    /// How long the test may take.
    var limit: Duration

    /// When that time is up.
    var deadline: ContinuousClock.Instant

    /// The time limit of the current test, if it has one.
    @TaskLocal static var current: TestTimeLimit?
}
