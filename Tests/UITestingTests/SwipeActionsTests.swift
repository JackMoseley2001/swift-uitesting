import Testing

@testable import UITesting

@Suite
struct SwipeActionsTests {
    @Test
    func actionsAreTheButtonsBesideTheRow() {
        let buttons = [(label: "Flag", identifier: "InboxID.flagButton-2"), (label: "Delete", identifier: "")]

        #Testing::expect(SwipeActions.labels(ofButtons: buttons, rowIdentifier: "InboxID.row-2") == ["Flag", "Delete"])
    }

    @Test
    func rowThatIsAButtonIsNotOneOfItsActions() {
        let buttons = [(label: "Invoice", identifier: "InboxID.row-2"), (label: "Delete", identifier: "")]

        #Testing::expect(SwipeActions.labels(ofButtons: buttons, rowIdentifier: "InboxID.row-2") == ["Delete"])
    }

    @Test
    func actionThatIsReportedTwiceIsListedOnce() {
        let buttons = [(label: "Delete", identifier: "delete"), (label: "Delete", identifier: "delete")]

        #Testing::expect(SwipeActions.labels(ofButtons: buttons, rowIdentifier: "row") == ["Delete"])
    }

    @Test
    func missingActionListsTheActionsThereAre() {
        let message = SwipeActions.missing(
            action: "\"Archive\"",
            row: "InboxID.row-2",
            edge: .trailing,
            shown: ["Flag", "Delete"]
        )

        #Testing::expect(
            message == """
                Could not use the swipe action "Archive" on InboxID.row-2: \
                its trailing side has no such action. Its actions are: "Flag", "Delete"
                """
        )
    }

    @Test
    func swipeThatShowsNothingSaysSo() {
        let message = SwipeActions.missing(action: "\"Read\"", row: "InboxID.row-2", edge: .leading, shown: [])

        #Testing::expect(
            message == """
                Could not use the swipe action "Read" on InboxID.row-2: \
                swiping showed no actions on its leading side
                """
        )
    }
}
