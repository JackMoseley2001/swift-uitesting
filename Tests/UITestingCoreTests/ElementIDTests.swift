import Testing
import UITestingCore

@Suite
struct ElementIDTests {
    @Test
    func identifierIsTheTypeNameAndTheCaseName() {
        #expect(LoginID.signInButton.accessibilityIdentifier == "LoginID.signInButton")
        #expect(LoginID.namespace == "LoginID")
        #expect(LoginID.signInButton.name == "signInButton")
    }

    @Test
    func sameCaseNameInTwoTypesGivesDifferentIdentifiers() {
        #expect(LoginID.title.accessibilityIdentifier != SettingsID.title.accessibilityIdentifier)
    }

    @Test
    func nestedTypesIncludeTheTypesTheyAreNestedIn() {
        #expect(LoginScreen.ID.title.accessibilityIdentifier == "LoginScreen.ID.title")
        #expect(SettingsScreen.ID.title.accessibilityIdentifier == "SettingsScreen.ID.title")
    }

    @Test
    func namespaceLeavesOutTheModule() {
        #expect(LoginID.namespace?.contains("UITestingCoreTests") == false)
        #expect(LoginScreen.ID.namespace?.contains("UITestingCoreTests") == false)
    }

    @Test
    func privateTypeUsesItsOwnName() {
        #expect(PrivateID.only.accessibilityIdentifier == "PrivateID.only")
    }

    @Test
    func localTypeLeavesOutContextsThatHaveNoName() {
        enum LocalID: ElementID {
            case only
        }

        let identifier = LocalID.only.accessibilityIdentifier

        #expect(identifier.hasSuffix("LocalID.only"))
        #expect(!identifier.contains("("))
        #expect(!identifier.contains("UITestingCoreTests"))
    }

    @Test
    func genericTypeKeepsItsArguments() {
        #expect(Wrapper<Int>.ID.only.accessibilityIdentifier == "Wrapper<Swift.Int>.ID.only")
    }

    @Test
    func associatedValueTellsRowsApart() {
        #expect(InboxID.row(1234).accessibilityIdentifier == "InboxID.row(1234)")
        #expect(InboxID.row(1234).accessibilityIdentifier != InboxID.row(1235).accessibilityIdentifier)
        #expect(InboxID.list.accessibilityIdentifier == "InboxID.list")
    }

    @Test
    func associatedValuesKeepTheirLabels() {
        #expect(InboxID.deleteButton(row: 7).accessibilityIdentifier == "InboxID.deleteButton(row: 7)")
        #expect(InboxID.attachment(message: "a1", index: 2).name == #"attachment(message: "a1", index: 2)"#)
    }

    @Test
    func rawStringValueIsUsedAsTheName() {
        #expect(RawValueID.signInButton.accessibilityIdentifier == "RawValueID.sign-in-button")
    }

    @Test
    func rawIntegerValueIsNotUsedAsTheName() {
        #expect(IntegerRawValueID.first.accessibilityIdentifier == "IntegerRawValueID.first")
    }

    @Test
    func namespaceCanBeChosen() {
        #expect(RenamedID.title.accessibilityIdentifier == "login.title")
    }

    @Test
    func namespaceCanBeLeftOut() {
        #expect(LegacyID.signInButton.accessibilityIdentifier == "sign-in-button")
    }

    @Test
    func nameCanBeChosen() {
        #expect(CustomNameID(row: 3).accessibilityIdentifier == "CustomNameID.row-3")
    }
}

private enum PrivateID: ElementID {
    case only
}

enum LoginID: ElementID {
    case title
    case signInButton
}

enum SettingsID: ElementID {
    case title
}

enum LoginScreen {
    enum ID: ElementID {
        case title
    }
}

enum SettingsScreen {
    enum ID: ElementID {
        case title
    }
}

enum Wrapper<Value> {
    enum ID: ElementID {
        case only
    }
}

enum InboxID: ElementID {
    case list
    case row(Int)
    case deleteButton(row: Int)
    case attachment(message: String, index: Int)
}

enum RawValueID: String, ElementID {
    case signInButton = "sign-in-button"
}

enum IntegerRawValueID: Int, ElementID {
    case first = 1
}

enum RenamedID: ElementID {
    case title

    static var namespace: String? { "login" }
}

enum LegacyID: String, ElementID {
    case signInButton = "sign-in-button"

    static var namespace: String? { nil }
}

struct CustomNameID: ElementID {
    var row: Int

    var name: String { "row-\(row)" }
}
