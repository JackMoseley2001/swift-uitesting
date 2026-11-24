import CoreGraphics
import Testing

@testable import UITesting

@Suite
struct AppAlertTests {
    private let buttons = [SystemAlertButtonInfo(label: "Cancel"), SystemAlertButtonInfo(label: "Delete")]

    @Test
    func messageIsTheTextAfterTheTitle() {
        let texts = ["Delete the draft?", "This cannot be undone."]

        #Testing::expect(AppAlertText.message(title: "Delete the draft?", texts: texts) == "This cannot be undone.")
    }

    @Test
    func alertWithOnlyATitleHasNoMessage() {
        #Testing::expect(AppAlertText.message(title: "Delete the draft?", texts: ["Delete the draft?"]) == nil)
        #Testing::expect(AppAlertText.message(title: "Delete the draft?", texts: []) == nil)
    }

    @Test
    func titleThatIsReportedTwiceIsNotTheMessage() {
        // watchOS reports the title again after the other text.
        let title = "Delete the draft?"

        let message = AppAlertText.message(title: title, texts: [title, "This cannot be undone.", title])
        #Testing::expect(message == "This cannot be undone.")
        #Testing::expect(AppAlertText.message(title: title, texts: [title, title]) == nil)
    }

    @Test
    func messageIsFoundWhenTheTitleIsNotAmongTheTexts() {
        #Testing::expect(AppAlertText.message(title: "", texts: ["This cannot be undone."]) == "This cannot be undone.")
    }

    @Test
    func failureNamesAnAlertOfTheApp() {
        let choice = SystemAlertChoice.position(
            of: .label("Remove"),
            inAlertTitled: "Delete the draft?",
            withButtons: buttons,
            noun: .alert
        )
        let expected = """
            Could not tap "Remove" in the alert "Delete the draft?": \
            the alert has no button with this label. Its buttons are: "Cancel", "Delete"
            """

        #Testing::expect(choice == .failure(SystemAlertChoiceError(message: expected)))
    }

    @Test
    func failureNamesADialog() {
        let choice = SystemAlertChoice.position(
            of: .index(4),
            inAlertTitled: "Share the draft?",
            withButtons: buttons,
            noun: .dialog
        )
        let expected = """
            Could not tap button 4 in the dialog "Share the draft?": \
            the dialog has 2 buttons. Its buttons are: "Cancel", "Delete"
            """

        #Testing::expect(choice == .failure(SystemAlertChoiceError(message: expected)))
    }

    @Test
    func messagesAboutWaitingNameWhatWasWaitedFor() {
        #Testing::expect(
            SystemAlertChoice.noAlert(inOrderTo: "find an alert", after: .seconds(5), noun: .alert)
                == "Could not find an alert: no alert appeared within 5 seconds"
        )
        #Testing::expect(
            SystemAlertChoice.alertStayed(titled: "Share the draft?", after: .seconds(1), noun: .dialog)
                == "The dialog \"Share the draft?\" was still showing after 1 second"
        )
    }

    @Test
    func pointOutsideAnActionSheetIsInTheSpaceAboveIt() {
        let screen = CGRect(x: 0, y: 0, width: 400, height: 800)
        let sheet = CGRect(x: 8, y: 600, width: 384, height: 180)

        #Testing::expect(AppAlertText.offsetOutside(sheet, in: screen) == CGVector(dx: 0.5, dy: 0.375))
    }

    @Test
    func pointOutsideADialogAtTheTopIsBelowIt() {
        let screen = CGRect(x: 0, y: 0, width: 400, height: 800)
        let dialog = CGRect(x: 8, y: 0, width: 384, height: 400)

        #Testing::expect(AppAlertText.offsetOutside(dialog, in: screen) == CGVector(dx: 0.5, dy: 0.75))
    }

    @Test
    func dialogThatFillsTheScreenHasNoPointOutside() {
        let screen = CGRect(x: 0, y: 0, width: 400, height: 800)

        #Testing::expect(AppAlertText.offsetOutside(screen, in: screen) == nil)
        #Testing::expect(AppAlertText.offsetOutside(.zero, in: .zero) == nil)
    }
}
