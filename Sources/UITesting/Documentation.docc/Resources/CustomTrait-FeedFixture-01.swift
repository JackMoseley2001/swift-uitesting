import UITesting

/// Launches the app with a canned response in place of the feed from the server.
struct FeedFixture: UITestTrait {
    /// The name of a response bundled with the app.
    var name: String

    func prepare(_ launch: inout LaunchConfiguration) {
        launch.environment["FEED_FIXTURE"] = name
    }
}
