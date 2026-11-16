import Foundation
import Testing
import UITestingCore

@Suite
struct ElementIDTests {
    @Test
    func identifierIsTheGroupNameAndTheMemberName() {
        #expect(LoginID.signInButton.accessibilityIdentifier == "LoginID.signInButton")
        #expect(LoginID.namespace == "LoginID")
    }

    @Test
    func sameMemberNameInTwoGroupsGivesDifferentIdentifiers() {
        #expect(LoginID.title.accessibilityIdentifier == "LoginID.title")
        #expect(SettingsID.title.accessibilityIdentifier == "SettingsID.title")
    }

    @Test
    func nestedGroupsIncludeTheTypesTheyAreNestedIn() {
        #expect(LoginScreen.ID.title.accessibilityIdentifier == "LoginScreen.ID.title")
        #expect(SettingsScreen.ID.title.accessibilityIdentifier == "SettingsScreen.ID.title")
    }

    @Test
    func namespaceLeavesOutTheModule() {
        #expect(LoginID.namespace?.contains("UITestingCoreTests") == false)
        #expect(LoginScreen.ID.namespace?.contains("UITestingCoreTests") == false)
    }

    @Test
    func privateGroupUsesItsOwnName() {
        #expect(PrivateID.only.accessibilityIdentifier == "PrivateID.only")
    }

    @Test
    func localGroupLeavesOutContextsThatHaveNoName() {
        enum LocalID: ElementIDs {
            static var only: Button { element() }
        }

        let identifier = LocalID.only.accessibilityIdentifier

        #expect(identifier.hasSuffix("LocalID.only"))
        #expect(!identifier.contains("("))
        #expect(!identifier.contains("UITestingCoreTests"))
    }

    @Test
    func argumentTellsRowsApart() {
        #expect(InboxID.row(1234).accessibilityIdentifier == "InboxID.row(1234)")
        #expect(InboxID.row(1234) != InboxID.row(1235))
        #expect(InboxID.row(1234) == InboxID.row(1234))
        #expect(InboxID.list.accessibilityIdentifier == "InboxID.list")
    }

    @Test
    func argumentsKeepTheirLabels() {
        #expect(InboxID.deleteButton(row: 7).accessibilityIdentifier == "InboxID.deleteButton(row: 7)")
        #expect(
            InboxID.attachment("a1", index: 2).accessibilityIdentifier == "InboxID.attachment(a1, index: 2)"
        )
    }

    @Test
    func functionsWithDifferentLabelsGiveDifferentIdentifiers() {
        #expect(InboxID.badge(row: 1).accessibilityIdentifier == "InboxID.badge(row: 1)")
        #expect(InboxID.badge(section: 1).accessibilityIdentifier == "InboxID.badge(section: 1)")
    }

    @Test
    func labelsAreLeftOutWhenNotEveryArgumentIsPassedOn() {
        #expect(InboxID.header(section: 3, style: "plain").accessibilityIdentifier == "InboxID.header(3)")
    }

    @Test
    func uuidArgumentIsDescribedByItsString() {
        let id = UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!

        #expect(InboxID.draft(id).accessibilityIdentifier == "InboxID.draft(E621E1F8-C36C-495A-93FC-0C247A3E6E5F)")
    }

    @Test
    func nameCanBeChosen() {
        #expect(RenamedID.title.accessibilityIdentifier == "login.heading")
    }

    @Test
    func namespaceCanBeChosen() {
        #expect(RenamedID.subtitle.accessibilityIdentifier == "login.subtitle")
    }

    @Test
    func namespaceCanBeLeftOut() {
        #expect(UnprefixedID.signInButton.accessibilityIdentifier == "signInButton")
    }

    @Test
    func identifierCanBeAnExactString() {
        #expect(LegacyID.signInButton.accessibilityIdentifier == "sign-in-button")
    }

    @Test
    func identifierKnowsItsKindOfElement() {
        #expect(elementType(of: LoginID.title) == .staticText)
        #expect(elementType(of: LoginID.emailField) == .textField)
        #expect(elementType(of: LoginID.signInButton) == .button)
        #expect(elementType(of: InboxID.row(1)) == .cell)
        #expect(elementType(of: InboxID.list) == .any)
    }

    @Test
    func customKindCanBeUsed() {
        #expect(elementType(of: CustomKindID.rating) == .slider)
    }

    @Test
    func everyElementTypeHasAKind() {
        let kinds: [any ElementKind.Type] = [
            ElementKinds.AnyElement.self, ElementKinds.Other.self, ElementKinds.Button.self,
            ElementKinds.StaticText.self, ElementKinds.TextField.self, ElementKinds.SecureTextField.self,
            ElementKinds.TextView.self, ElementKinds.SearchField.self, ElementKinds.Switch.self,
            ElementKinds.Toggle.self, ElementKinds.CheckBox.self, ElementKinds.RadioButton.self,
            ElementKinds.Slider.self, ElementKinds.Stepper.self, ElementKinds.Picker.self,
            ElementKinds.PickerWheel.self, ElementKinds.DatePicker.self, ElementKinds.SegmentedControl.self,
            ElementKinds.PopUpButton.self, ElementKinds.MenuButton.self, ElementKinds.Menu.self,
            ElementKinds.MenuItem.self, ElementKinds.Image.self, ElementKinds.Icon.self,
            ElementKinds.Link.self, ElementKinds.Cell.self, ElementKinds.Table.self,
            ElementKinds.CollectionView.self, ElementKinds.ScrollView.self, ElementKinds.NavigationBar.self,
            ElementKinds.TabBar.self, ElementKinds.Tab.self, ElementKinds.Toolbar.self,
            ElementKinds.Alert.self, ElementKinds.Sheet.self, ElementKinds.Window.self,
            ElementKinds.Group.self, ElementKinds.WebView.self, ElementKinds.Map.self,
            ElementKinds.ProgressIndicator.self, ElementKinds.ActivityIndicator.self,
            ElementKinds.PageIndicator.self, ElementKinds.Keyboard.self, ElementKinds.Key.self,
        ]

        #expect(Set(kinds.map { $0.elementType }) == Set(ElementType.allCases))
        #expect(kinds.count == ElementType.allCases.count)
    }
}

private func elementType<Kind: ElementKind>(of id: ElementID<Kind>) -> ElementType {
    Kind.elementType
}

private enum PrivateID: ElementIDs {
    static var only: Button { element() }
}

enum LoginID: ElementIDs {
    static var title: StaticText { element() }
    static var emailField: TextField { element() }
    static var signInButton: Button { element() }
}

enum SettingsID: ElementIDs {
    static var title: StaticText { element() }
}

enum LoginScreen {
    enum ID: ElementIDs {
        static var title: StaticText { element() }
    }
}

enum SettingsScreen {
    enum ID: ElementIDs {
        static var title: StaticText { element() }
    }
}

enum InboxID: ElementIDs {
    static var list: AnyElement { element() }
    static func row(_ id: Int) -> Cell { element(id) }
    static func deleteButton(row: Int) -> Button { element(row) }
    static func attachment(_ message: String, index: Int) -> Image { element(message, index) }
    static func badge(row: Int) -> StaticText { element(row) }
    static func badge(section: Int) -> StaticText { element(section) }
    static func header(section: Int, style: String) -> StaticText { element(section) }
    static func draft(_ id: UUID) -> Cell { element(id) }
}

enum RenamedID: ElementIDs {
    static var namespace: String? { "login" }

    static var title: StaticText { element(name: "heading") }
    static var subtitle: StaticText { element() }
}

enum UnprefixedID: ElementIDs {
    static var namespace: String? { nil }

    static var signInButton: Button { element() }
}

enum LegacyID: ElementIDs {
    static var signInButton: Button { Button("sign-in-button") }
}

enum RatingControl: ElementKind {
    static var elementType: ElementType { .slider }
}

enum CustomKindID: ElementIDs {
    static var rating: ElementID<RatingControl> { element() }
}
