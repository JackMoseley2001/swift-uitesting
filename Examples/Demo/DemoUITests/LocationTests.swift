import UITesting
import XCTest

@UITestSuite(
    traits: .example(.location),
    .systemAlerts(.button("Allow While Using App"), for: .location),
    .animationsDisabled
)
final class LocationTests: XCTestCase {
    @UITest(traits: .location(latitude: 51.5074, longitude: -0.1278))
    func theAppIsWhereTheTestPutTheDevice(app: XCUIApplication) throws {
        try app[LocationID.findButton].tap()

        #expect(app[LocationID.coordinates].label == "51.5074, -0.1278", within: .seconds(10))
    }

    @UITest(traits: .location(latitude: -33.8688, longitude: 151.2093))
    func anotherTestCanPutItSomewhereElse(app: XCUIApplication) throws {
        try app[LocationID.findButton].tap()

        #expect(app[LocationID.coordinates].label == "-33.8688, 151.2093", within: .seconds(10))
    }
}
