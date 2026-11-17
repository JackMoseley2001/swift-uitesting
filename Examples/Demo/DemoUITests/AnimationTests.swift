import UITesting
import XCTest

// The only suite that runs with animations, because it checks that they run.
@UITestSuite(traits: .example(.animation))
final class AnimationTests: XCTestCase {
    @UITest
    func anAnimationTakesItsTime(app: XCUIApplication) throws {
        #expect(app[AnimationID.status].label == "Animations enabled")
        let clock = ContinuousClock()

        try app[AnimationID.moveButton].tap()
        let start = clock.now
        try app[AnimationID.arrived].waitToAppear(within: .seconds(6))

        #expect(clock.now - start > .seconds(2))
    }

    @UITest(traits: .animationsDisabled)
    func aTestCanTurnAnimationsOff(app: XCUIApplication) throws {
        #expect(app[AnimationID.status].label == "Animations disabled")
        let clock = ContinuousClock()

        try app[AnimationID.moveButton].tap()
        let start = clock.now
        try app[AnimationID.arrived].waitToAppear(within: .seconds(6))

        #expect(clock.now - start < .seconds(1))
    }
}
