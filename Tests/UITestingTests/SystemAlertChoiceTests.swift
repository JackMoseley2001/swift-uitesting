import Testing

@testable import UITesting

@Suite
struct SystemAlertChoiceTests {
    private let title = "Allow “Demo” to access your microphone?"
    private let buttons = [
        SystemAlertButtonInfo(label: "Don’t Allow", identifier: "kTCCServiceMicrophone-deny-button"),
        SystemAlertButtonInfo(label: "Allow", identifier: "kTCCServiceMicrophone-allow-button")
    ]

    private func position(
        of button: SystemAlertButton,
        in buttons: [SystemAlertButtonInfo]? = nil
    ) -> Result<Int, SystemAlertChoiceError> {
        SystemAlertChoice.position(of: button, inAlertTitled: title, withButtons: buttons ?? self.buttons)
    }

    @Test
    func buttonIsFoundByItsLabel() {
        #Testing::expect(position(of: .label("Allow")) == .success(1))
        #Testing::expect(position(of: .label("Don’t Allow")) == .success(0))
    }

    @Test
    func buttonIsFoundByItsPosition() {
        #Testing::expect(position(of: .index(0)) == .success(0))
        #Testing::expect(position(of: .index(1)) == .success(1))
    }

    @Test
    func buttonsThatAllowAndRefuseAreFoundByTheirIdentifiers() {
        #Testing::expect(position(of: .allow) == .success(1))
        #Testing::expect(position(of: .deny) == .success(0))
    }

    @Test
    func allowAndRefuseDoNotDependOnTheLabels() {
        let french = [
            SystemAlertButtonInfo(label: "Refuser", identifier: "kTCCServiceCamera-deny-button"),
            SystemAlertButtonInfo(label: "Autoriser", identifier: "kTCCServiceCamera-allow-button")
        ]

        #Testing::expect(position(of: .allow, in: french) == .success(1))
        #Testing::expect(position(of: .deny, in: french) == .success(0))
    }

    @Test
    func missingLabelListsTheButtonsThereAre() {
        let expected = """
            Could not tap "Nope" in the system alert "Allow “Demo” to access your microphone?": \
            the alert has no button with this label. Its buttons are: "Don’t Allow", "Allow"
            """

        #Testing::expect(position(of: .label("Nope")) == .failure(SystemAlertChoiceError(message: expected)))
    }

    @Test
    func labelWithAStraightApostropheDoesNotMatch() {
        guard case .failure = position(of: .label("Don't Allow")) else {
            Issue.record("A label that differs only in its apostrophe was matched")
            return
        }
    }

    @Test
    func positionPastTheEndSaysHowManyButtonsThereAre() {
        let expected = """
            Could not tap button 5 in the system alert "Allow “Demo” to access your microphone?": \
            the alert has 2 buttons. Its buttons are: "Don’t Allow", "Allow"
            """

        #Testing::expect(position(of: .index(5)) == .failure(SystemAlertChoiceError(message: expected)))
        guard case .failure = position(of: .index(-1)) else {
            Issue.record("A negative position was accepted")
            return
        }
    }

    @Test
    func alertThatDoesNotSayWhichButtonAllowsFails() {
        let plain = [SystemAlertButtonInfo(label: "OK"), SystemAlertButtonInfo(label: "Cancel")]
        let expected = """
            Could not tap the button that allows in the system alert "Allow “Demo” to access your microphone?": \
            the alert does not say which of its buttons that is. Its buttons are: "OK", "Cancel"
            """

        #Testing::expect(position(of: .allow, in: plain) == .failure(SystemAlertChoiceError(message: expected)))
    }

    @Test
    func repeatedButtonsAreLeftOut() {
        // The order the system reports them in: each button, then each again.
        let reported = buttons + buttons

        #Testing::expect(SystemAlertChoice.positionsWithoutRepeats(in: reported) == [0, 1])
        #Testing::expect(SystemAlertChoice.positionsWithoutRepeats(in: [buttons[0], buttons[0], buttons[1]]) == [0, 2])
        #Testing::expect(SystemAlertChoice.positionsWithoutRepeats(in: []) == [])
    }

    @Test
    func buttonsWithTheSameLabelButDifferentIdentifiersAreKept() {
        let reported = [
            SystemAlertButtonInfo(label: "Allow", identifier: "first"),
            SystemAlertButtonInfo(label: "Allow", identifier: "second")
        ]

        #Testing::expect(SystemAlertChoice.positionsWithoutRepeats(in: reported) == [0, 1])
    }

    @Test
    func messagesSayHowLongWasWaited() {
        #Testing::expect(
            SystemAlertChoice.noAlert(inOrderTo: "tap \"Allow\" in a system alert", after: .seconds(5))
                == "Could not tap \"Allow\" in a system alert: no system alert appeared within 5 seconds"
        )
        #Testing::expect(
            SystemAlertChoice.alertStayed(titled: "Allow access?", after: .seconds(1))
                == "The system alert \"Allow access?\" was still showing after 1 second"
        )
    }
}
