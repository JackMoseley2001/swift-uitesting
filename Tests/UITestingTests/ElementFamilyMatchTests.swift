import Foundation
import Testing

@testable import UITesting

@Suite
struct ElementFamilyMatchTests {
    @Test
    func prefixIsTheOneTheFamilyGives() {
        #Testing::expect(ElementFamilyMatch(ConversationID.row).identifierPrefix == "ConversationID.row(")
        #Testing::expect(ElementFamilyMatch(ConversationID.attachment).identifierPrefix == "ConversationID.attachment(")
        #Testing::expect(ElementFamilyMatch(UnprefixedConversationID.row).identifierPrefix == "row(")
    }

    // Foundation can only make a predicate from a format on Apple's platforms.
    #if canImport(Darwin)
        @Test
        func predicateMatchesTheIdentifiersOfTheFamily() {
            let predicate = ElementFamilyMatch(ConversationID.row).predicate

            for id in [ConversationID.row(1), ConversationID.row(1234)] {
                #Testing::expect(predicate.evaluate(with: ["identifier": id.accessibilityIdentifier]))
            }
        }

        @Test
        func predicateDoesNotMatchOtherIdentifiers() {
            let predicate = ElementFamilyMatch(ConversationID.row).predicate
            let others = [
                ConversationID.rowTitle.accessibilityIdentifier,
                ConversationID.attachment("a1").accessibilityIdentifier,
                UnprefixedConversationID.row(1).accessibilityIdentifier,
                "Other.ConversationID.row(1)",
                "conversationid.row(1)",
                ""
            ]

            for identifier in others {
                #Testing::expect(!predicate.evaluate(with: ["identifier": identifier]), "\(identifier)")
            }
        }
    #endif

    @Test
    func elementThatIsNotThereIsNamedByTheFamilyAndThePosition() {
        let rows = ElementFamilyMatch(ConversationID.row)

        #Testing::expect(rows.description(ofElementAt: 0) == "ConversationID.row(…)[0]")
        #Testing::expect(rows.description(ofElementAt: 12) == "ConversationID.row(…)[12]")
        #Testing::expect(ElementFamilyMatch(UnprefixedConversationID.row).description(ofElementAt: 2) == "row(…)[2]")
    }

    @Test
    func failureOfAnActionNamesTheFamilyAndThePosition() {
        let clock = FamilyTestClock()
        let failure = ElementWait.failure(
            intent: "tap",
            identifier: ElementFamilyMatch(ConversationID.row).description(ofElementAt: 2),
            kind: "cell",
            requirement: .enabled,
            timeout: .seconds(5),
            polling: ExpectationPolling(interval: .seconds(1), now: { clock.advance() }, sleep: { _ in }),
            probe: ElementProbe(exists: { false }, isEnabled: { true }, typeOfElementWithSameIdentifier: { nil })
        )

        #Testing::expect(
            failure == "Could not tap ConversationID.row(…)[2]: no cell with this identifier appeared within 5 seconds"
        )
    }
}

private enum ConversationID: ElementIDs {
    static var row: Cell.Family<Int> { family() }
    static var attachment: Image.Family<String> { family() }
    static var rowTitle: StaticText { element() }
}

private enum UnprefixedConversationID: ElementIDs {
    static var namespace: String? { nil }

    static var row: Cell.Family<Int> { family() }
}

/// A clock that moves on one second at each check of the time.
private final class FamilyTestClock {
    private var instant = ContinuousClock.now

    func advance() -> ContinuousClock.Instant {
        defer { instant += .seconds(1) }
        return instant
    }
}
