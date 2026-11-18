import Testing

@testable import UITesting

@Suite
struct ElementReferenceTests {
    private let button = ElementReference.label("Continue", kind: "button")

    /// Polling that never sleeps, with a clock that moves on one second at each check of the time.
    private func polling() -> ExpectationPolling {
        var instant = ContinuousClock.now
        return ExpectationPolling(
            interval: .seconds(1),
            now: {
                defer { instant += .seconds(1) }
                return instant
            },
            sleep: { _ in }
        )
    }

    private func failure(
        intent: String = "tap",
        element: ElementReference? = nil,
        kind: String = "button",
        requirement: ElementRequirement,
        exists: @escaping () -> Bool,
        isEnabled: @escaping () -> Bool = { true },
        otherType: String? = nil,
        matchCount: (() -> Int)? = nil
    ) -> String? {
        ElementWait.failure(
            intent: intent,
            element: element ?? button,
            kind: kind,
            requirement: requirement,
            timeout: .seconds(5),
            polling: polling(),
            probe: ElementProbe(
                exists: exists,
                isEnabled: isEnabled,
                typeOfElementWithSameIdentifier: { otherType },
                matchCount: matchCount
            )
        )
    }

    @Test
    func elementFoundByAnIdentifierIsCalledByIt() {
        let reference = ElementReference.identifier("LoginID.signInButton")

        #Testing::expect(reference.name == "LoginID.signInButton")
        #Testing::expect(reference.attribute == "identifier")
    }

    @Test
    func elementFoundByALabelIsCalledByItsKindAndLabel() {
        #Testing::expect(button.name == "the button labelled \"Continue\"")
        #Testing::expect(button.attribute == "label")
        #Testing::expect(
            ElementReference.label("Continue", kind: "element").name == "the element labelled \"Continue\""
        )
    }

    @Test
    func hintForAnIdentifierAsksAboutItsDeclaration() {
        let reference = ElementReference.identifier("LoginID.title")

        #Testing::expect(
            reference.hint(forElementOfType: "staticText")
                == "An element of type staticText has this identifier. Is the identifier declared as the wrong kind?"
        )
        #Testing::expect(
            reference.hint(forElementOfType: nil)
                == "An element of another kind has this identifier. Is the identifier declared as the wrong kind?"
        )
    }

    @Test
    func hintForALabelAsksAboutTheLookup() {
        #Testing::expect(
            button.hint(forElementOfType: "staticText")
                == "An element of type staticText has this label. Should the lookup be for that kind?"
        )
        #Testing::expect(
            button.hint(forElementOfType: nil)
                == "An element of another kind has this label. Should the lookup be for that kind?"
        )
    }

    @Test
    func unknownAppSaysWhereToLookTheElementUp() {
        #Testing::expect(
            ElementReference.identifier("DatesID.datePicker").reasonForUnknownApp == """
                the element was looked up in a query, so the app it belongs to is not known. \
                Look it up in the app, as in app[id]
                """
        )
        #Testing::expect(
            ElementReference.label("Due", kind: "datePicker").reasonForUnknownApp == """
                the element was looked up in an element that is not the app and was not found in it, \
                so the app it belongs to is not known. Look it up in the app, or in an element found in the app
                """
        )
    }

    @Test
    func elementFoundByALabelThatIsReadyPasses() {
        #Testing::expect(failure(requirement: .enabled, exists: { true }, matchCount: { 1 }) == nil)
        #Testing::expect(failure(requirement: .exists, exists: { true }, matchCount: { 1 }) == nil)
        #Testing::expect(failure(requirement: .absent, exists: { false }, matchCount: { 0 }) == nil)
    }

    @Test
    func missingElementSaysNothingWithTheLabelAppeared() {
        #Testing::expect(
            failure(requirement: .enabled, exists: { false }, matchCount: { 0 })
                == "Could not tap the button labelled \"Continue\": no button with this label appeared within 5 seconds"
        )
    }

    @Test
    func elementOfAnotherKindWithTheLabelIsPointedOut() {
        #Testing::expect(
            failure(requirement: .exists, exists: { false }, otherType: "staticText", matchCount: { 0 }) == """
                Could not tap the button labelled "Continue": no button with this label appeared within 5 seconds
                An element of type staticText has this label. Should the lookup be for that kind?
                """
        )
    }

    @Test
    func disabledElementSaysItStayedDisabled() {
        #Testing::expect(
            failure(requirement: .enabled, exists: { true }, isEnabled: { false }, matchCount: { 1 })
                == "Could not tap the button labelled \"Continue\": the button was still disabled after 5 seconds"
        )
    }

    @Test
    func elementThatStaysSaysItWasStillThere() {
        let failure = failure(
            intent: "see the end of",
            element: .label("Loading", kind: "staticText"),
            kind: "staticText",
            requirement: .absent,
            exists: { true },
            matchCount: { 1 }
        )

        #Testing::expect(
            failure
                == "Could not see the end of the staticText labelled \"Loading\": "
                + "the staticText was still there after 5 seconds"
        )
    }

    @Test
    func severalElementsWithTheLabelAreAFailure() {
        #Testing::expect(
            failure(requirement: .exists, exists: { true }, matchCount: { 2 }) == """
                Could not tap the button labelled "Continue": 2 elements match, and a lookup by label does not \
                choose between them. Look inside the element that holds the one you mean
                """
        )
    }

    @Test
    func severalElementsAreReportedWithoutWaitingOrReadingFromThem() {
        var existenceChecks = 0
        var enabledReads = 0

        let failure = failure(
            requirement: .enabled,
            exists: {
                existenceChecks += 1
                return true
            },
            isEnabled: {
                enabledReads += 1
                return false
            },
            matchCount: { 3 }
        )

        #Testing::expect(failure?.contains("3 elements match") == true)
        #Testing::expect(existenceChecks == 1)
        #Testing::expect(enabledReads == 0)
    }

    @Test
    func severalElementsThatXCTestReportsAsMissingAreStillAFailure() {
        let failure = failure(requirement: .exists, exists: { false }, otherType: "button", matchCount: { 2 })

        #Testing::expect(failure?.hasPrefix("Could not tap the button labelled \"Continue\": 2 elements match") == true)
    }

    @Test
    func severalElementsThatHaveToGoAreWaitedFor() {
        var checks = 0

        let failure = failure(
            requirement: .absent,
            exists: {
                checks += 1
                return checks < 3
            },
            matchCount: { 2 }
        )

        #Testing::expect(failure == nil)
    }

    @Test
    func matchesAreNotCountedWhileTheElementIsMissing() {
        var counts = 0

        _ = failure(
            requirement: .exists,
            exists: { false },
            matchCount: {
                counts += 1
                return 0
            }
        )

        // Once, when the wait is over, to tell an element that is missing from several that match.
        #Testing::expect(counts == 1)
    }

    @Test
    func elementFoundByAnIdentifierIsDescribedAsBefore() {
        let failure = failure(
            element: .identifier("LoginID.signInButton"),
            requirement: .exists,
            exists: { false },
            otherType: "staticText"
        )

        #Testing::expect(
            failure == """
                Could not tap LoginID.signInButton: no button with this identifier appeared within 5 seconds
                An element of type staticText has this identifier. Is the identifier declared as the wrong kind?
                """
        )
    }
}
