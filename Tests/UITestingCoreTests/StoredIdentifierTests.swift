import Testing
@testable import UITestingCore

@Suite
struct StoredIdentifierTests {
    @Test
    func storedPropertyGivesTheNameOfItsType() {
        #expect(ElementName.isFromStoredProperty(MemberNames.storedLet, in: MemberNames.self))
        #expect(ElementName.isFromStoredProperty(MemberNames.storedVar, in: MemberNames.self))
        #expect(ElementName.isFromStoredProperty(MemberNames.storedClosure, in: MemberNames.self))
        #expect(ElementName.isFromStoredProperty(MemberNames.storedInExtension, in: MemberNames.self))
    }

    @Test
    func storedPropertyIsRecognisedInAStructAndAClass() {
        #expect(ElementName.isFromStoredProperty(StructNames.stored, in: StructNames.self))
        #expect(ElementName.isFromStoredProperty(ClassNames.stored, in: ClassNames.self))
    }

    @Test
    func storedPropertyOfANestedTypeLeavesOutTheTypesItIsNestedIn() {
        #expect(NestedNames.ID.stored == "ID")
        #expect(ElementName.isFromStoredProperty(NestedNames.ID.stored, in: NestedNames.ID.self))
        #expect(!ElementName.isFromStoredProperty("NestedNames.ID", in: NestedNames.ID.self))
    }

    @Test
    func storedPropertyOfAGenericTypeLeavesOutItsArguments() {
        let stored = GenericNames<Int>().stored

        #expect(stored == "GenericNames")
        #expect(ElementName.isFromStoredProperty(stored, in: GenericNames<Int>.self))
    }

    @Test
    func storedPropertyOfAPrivateOrLocalTypeIsRecognised() {
        enum LocalNames {
            static let stored = memberName()
        }

        #expect(ElementName.isFromStoredProperty(PrivateNames.stored, in: PrivateNames.self))
        #expect(ElementName.isFromStoredProperty(LocalNames.stored, in: LocalNames.self))
    }

    @Test
    func computedPropertyIsNotMistakenForAStoredOne() {
        #expect(MemberNames.computed == "computed")
        #expect(!ElementName.isFromStoredProperty(MemberNames.computed, in: MemberNames.self))
        #expect(!ElementName.isFromStoredProperty(MemberNames.closureInComputed, in: MemberNames.self))
    }

    @Test
    func functionIsNotMistakenForAStoredProperty() {
        #expect(!ElementName.isFromStoredProperty(MemberNames.noArguments(), in: MemberNames.self))
        #expect(!ElementName.isFromStoredProperty(MemberNames.row(1), in: MemberNames.self))
        #expect(!ElementName.isFromStoredProperty(MemberNames.deleteButton(row: 1), in: MemberNames.self))
        #expect(!ElementName.isFromStoredProperty(MemberNames.MemberNames(1), in: MemberNames.self))
    }

    @Test
    func chosenNameIsNotMistakenForAStoredProperty() {
        #expect(!ElementName.isFromStoredProperty("heading", in: MemberNames.self))
        #expect(!ElementName.isFromStoredProperty("memberNames", in: MemberNames.self))
        #expect(!ElementName.isFromStoredProperty("", in: MemberNames.self))
    }

    @Test
    func nameOfAnotherTypeIsNotMistakenForAStoredProperty() {
        #expect(!ElementName.isFromStoredProperty(StructNames.stored, in: MemberNames.self))
    }

    @Test
    func nameThatIsTheSameAsItsTypeCannotBeToldApart() {
        #expect(ElementName.isFromStoredProperty("MemberNames", in: MemberNames.self))
    }

    @Test
    func identifiersTheTestsDeclareAreNotStored() {
        #expect(!ElementName.isFromStoredProperty("signInButton", in: LoginID.self))
        #expect(!ElementName.isFromStoredProperty("title", in: LoginScreen.ID.self))
        #expect(!ElementName.isFromStoredProperty("row(_:)", in: InboxID.self))
    }

    @Test
    func messageNamesTheGroupAndTheFix() {
        let message = ElementName.storedPropertyMessage(member: "ID", in: LoginScreen.ID.self)

        #expect(message.contains("An identifier in LoginScreen.ID was given the name \"ID\""))
        #expect(message.contains("`static let title: StaticText = element()`"))
        #expect(message.contains("`static var title: StaticText { element() }`"))
        #expect(!message.contains("UITestingCoreTests"))
        #expect(!message.contains("\n"))
    }

    @Test
    func typeNameOnItsOwnLeavesOutNestingAndGenericArguments() {
        #expect(TypeName.unqualified(MemberNames.self) == "MemberNames")
        #expect(TypeName.unqualified(NestedNames.ID.self) == "ID")
        #expect(TypeName.unqualified(GenericNames<Int>.self) == "GenericNames")
        #expect(TypeName.unqualified(GenericNames<[String: NestedNames.ID]>.self) == "GenericNames")
        #expect(TypeName.unqualified(GenericNames<Int>.Inner.self) == "Inner")
        #expect(TypeName.unqualified(PrivateNames.self) == "PrivateNames")
    }
}

/// Returns what `#function` is where it is called from, as `element(_:name:)` receives it.
private func memberName(_ name: String = #function) -> String {
    name
}

// The names and kinds of type below are what the tests are about.
// swiftlint:disable convenience_type identifier_name

enum MemberNames {
    static let storedLet = memberName()
    nonisolated(unsafe) static var storedVar = memberName()
    static let storedClosure: String = { memberName() }()

    static var computed: String { memberName() }
    static var closureInComputed: String { { memberName() }() }

    static func noArguments() -> String { memberName() }
    static func row(_ id: Int) -> String { memberName() }
    static func deleteButton(row: Int) -> String { memberName() }
    static func MemberNames(_ id: Int) -> String { memberName() }
}

extension MemberNames {
    static let storedInExtension = memberName()
}

struct StructNames {
    static let stored = memberName()
}

final class ClassNames {
    static let stored = memberName()
}

// swiftlint:enable convenience_type identifier_name

enum NestedNames {
    enum ID {
        static let stored = memberName()
    }
}

/// A generic type cannot have a static stored property, so this one belongs to an instance.
struct GenericNames<Value> {
    let stored = memberName()

    enum Inner {}
}

private enum PrivateNames {
    static let stored = memberName()
}
