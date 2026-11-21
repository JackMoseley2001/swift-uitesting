import Testing

@testable import UITesting

@Suite
struct AppNavigationTests {
    @Test
    func failureSaysThatNoButtonToGoBackShowed() {
        let message = AppNavigation.noBackButton(after: .seconds(5))

        #Testing::expect(message.hasPrefix("Could not go back: no button to go back appeared within 5 seconds."))
    }

    @Test
    func backButtonIsFoundByAnIdentifierThatIsNotItsLabel() {
        #Testing::expect(AppNavigation.backButtonIdentifier == "BackButton")
        #Testing::expect(AppNavigation.macBackButtonIdentifier == "chevron.backward")
    }
}
