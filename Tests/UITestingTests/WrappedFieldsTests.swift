import Testing
@testable import UITesting

@Suite
struct WrappedFieldsTests {
    @Test
    func fieldIsLookedUpInsideWhatHasItsIdentifierWhereTheSystemDoesNotMarkIt() {
        #Testing::expect(WrappedFields.wraps(.textField, systemMarksFields: false))
        #Testing::expect(WrappedFields.wraps(.secureTextField, systemMarksFields: false))
    }

    @Test
    func fieldIsLookedUpItselfWhereTheSystemMarksIt() {
        #Testing::expect(!WrappedFields.wraps(.textField, systemMarksFields: true))
        #Testing::expect(!WrappedFields.wraps(.secureTextField, systemMarksFields: true))
    }

    @Test
    func otherElementsAreAlwaysLookedUpThemselves() {
        #Testing::expect(!WrappedFields.wraps(.button, systemMarksFields: false))
        #Testing::expect(!WrappedFields.wraps(.textView, systemMarksFields: false))
        #Testing::expect(!WrappedFields.wraps(.any, systemMarksFields: false))
    }
}
