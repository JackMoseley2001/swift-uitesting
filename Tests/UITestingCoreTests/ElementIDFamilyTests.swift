import Foundation
import Testing
import UITestingCore

@Suite
struct ElementIDFamilyTests {
    @Test
    func identifierIsTheSameAsTheFunctionFormGives() {
        #expect(ThreadID.row(1234).accessibilityIdentifier == "ThreadID.row(1234)")
        #expect(ThreadID.row(1234) == ThreadFunctionID.row(1234))
        #expect(ThreadID.row(1234) != ThreadID.row(1235))
    }

    @Test
    func identifierKnowsItsKindOfElement() {
        let row: ElementID<ElementKinds.Cell> = ThreadID.row(1)
        let reply: ElementID<ElementKinds.Button> = ThreadID.replyButton("a1")

        #expect(row.accessibilityIdentifier == "ThreadID.row(1)")
        #expect(reply.accessibilityIdentifier == "ThreadID.replyButton(a1)")
    }

    @Test
    func valuesAreDescribedTheWayPrintShowsThem() {
        let id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!

        #expect(ThreadID.replyButton("a1").accessibilityIdentifier == "ThreadID.replyButton(a1)")
        #expect(ThreadID.draft(id).accessibilityIdentifier == "ThreadID.draft(E621E1F8-C36C-495A-93FC-0C247A3E6E5F)")
        #expect(ThreadID.draft(id) == ThreadFunctionID.draft(id))
    }

    @Test
    func nestedGroupIncludesTheTypesItIsNestedIn() {
        #expect(ThreadScreen.ID.row(7).accessibilityIdentifier == "ThreadScreen.ID.row(7)")
    }

    @Test
    func namespaceCanBeChosen() {
        #expect(RenamedThreadID.row(7).accessibilityIdentifier == "thread.row(7)")
        #expect(RenamedThreadID.row(7) == RenamedThreadFunctionID.row(7))
    }

    @Test
    func namespaceCanBeLeftOut() {
        #expect(UnprefixedThreadID.row(7).accessibilityIdentifier == "row(7)")
        #expect(UnprefixedThreadID.row(7) == UnprefixedThreadFunctionID.row(7))
    }

    @Test
    func nameCanBeChosen() {
        #expect(RenamedThreadID.message(7).accessibilityIdentifier == "thread.item(7)")
    }

    @Test
    func nameCanKeepTheArgumentLabelOfAFunction() {
        #expect(ThreadID.deleteButton(7).accessibilityIdentifier == "ThreadID.deleteButton(row: 7)")
        #expect(ThreadID.deleteButton(7) == ThreadFunctionID.deleteButton(row: 7))
    }

    @Test
    func prefixIsTheIdentifierUpToTheValue() {
        #expect(ThreadID.row.accessibilityIdentifierPrefix == "ThreadID.row(")
        #expect(ThreadID.replyButton.accessibilityIdentifierPrefix == "ThreadID.replyButton(")
        #expect(ThreadScreen.ID.row.accessibilityIdentifierPrefix == "ThreadScreen.ID.row(")
    }

    @Test
    func prefixFollowsTheNamespaceAndTheName() {
        #expect(RenamedThreadID.row.accessibilityIdentifierPrefix == "thread.row(")
        #expect(RenamedThreadID.message.accessibilityIdentifierPrefix == "thread.item(")
        #expect(UnprefixedThreadID.row.accessibilityIdentifierPrefix == "row(")
        #expect(ThreadID.deleteButton.accessibilityIdentifierPrefix == "ThreadID.deleteButton(row: ")
    }

    @Test
    func everyIdentifierOfTheFamilyStartsWithThePrefix() {
        let id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!

        #expect(ThreadID.row(1234).accessibilityIdentifier.hasPrefix(ThreadID.row.accessibilityIdentifierPrefix))
        #expect(
            ThreadID.replyButton("").accessibilityIdentifier
                .hasPrefix(ThreadID.replyButton.accessibilityIdentifierPrefix)
        )
        #expect(ThreadID.draft(id).accessibilityIdentifier.hasPrefix(ThreadID.draft.accessibilityIdentifierPrefix))
        #expect(
            ThreadID.deleteButton(7).accessibilityIdentifier
                .hasPrefix(ThreadID.deleteButton.accessibilityIdentifierPrefix)
        )
        #expect(
            UnprefixedThreadID.row(7).accessibilityIdentifier
                .hasPrefix(UnprefixedThreadID.row.accessibilityIdentifierPrefix)
        )
    }

    @Test
    func memberWithALongerNameIsNotInTheFamily() {
        let prefix = ThreadID.row.accessibilityIdentifierPrefix

        #expect(!ThreadID.rowTitle.accessibilityIdentifier.hasPrefix(prefix))
        #expect(!ThreadID.rowTitleOf(1).accessibilityIdentifier.hasPrefix(prefix))
        #expect(!ThreadID.rowBadge(1).accessibilityIdentifier.hasPrefix(prefix))
        #expect(!ThreadID.row(1).accessibilityIdentifier.hasPrefix(ThreadID.rowBadge.accessibilityIdentifierPrefix))
    }

    @Test
    func sameNameInAnotherGroupIsNotInTheFamily() {
        let prefix = ThreadID.row.accessibilityIdentifierPrefix

        #expect(!ThreadScreen.ID.row(1).accessibilityIdentifier.hasPrefix(prefix))
        #expect(!RenamedThreadID.row(1).accessibilityIdentifier.hasPrefix(prefix))
    }
}

enum ThreadID: ElementIDs {
    static var row: Cell.Family<Int> { family() }
    static var replyButton: Button.Family<String> { family() }
    static var draft: Cell.Family<UUID> { family() }
    static var deleteButton: Button.Family<Int> { family(name: "deleteButton(row:)") }
    static var rowBadge: StaticText.Family<Int> { family() }

    static var rowTitle: StaticText { element() }
    static func rowTitleOf(_ id: Int) -> StaticText { element(id) }
}

/// The members of `ThreadID` written as functions, in a group with the same namespace.
enum ThreadFunctionID: ElementIDs {
    static var namespace: String? { "ThreadID" }

    static func row(_ id: Int) -> Cell { element(id) }
    static func draft(_ id: UUID) -> Cell { element(id) }
    static func deleteButton(row: Int) -> Button { element(row) }
}

enum ThreadScreen {
    enum ID: ElementIDs {
        static var row: Cell.Family<Int> { family() }
    }
}

enum RenamedThreadID: ElementIDs {
    static var namespace: String? { "thread" }

    static var row: Cell.Family<Int> { family() }
    static var message: Cell.Family<Int> { family(name: "item") }
}

enum RenamedThreadFunctionID: ElementIDs {
    static var namespace: String? { "thread" }

    static func row(_ id: Int) -> Cell { element(id) }
}

enum UnprefixedThreadID: ElementIDs {
    static var namespace: String? { nil }

    static var row: Cell.Family<Int> { family() }
}

enum UnprefixedThreadFunctionID: ElementIDs {
    static var namespace: String? { nil }

    static func row(_ id: Int) -> Cell { element(id) }
}
