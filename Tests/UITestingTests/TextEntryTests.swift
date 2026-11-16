import Testing
import XCTest

@testable import UITesting

@Suite
struct TextEntryTests {
    @Test
    func textIsTheValueOfTheField() {
        #Testing::expect(TextEntry.text(value: "Ada", placeholder: "Name") == "Ada")
        #Testing::expect(TextEntry.text(value: "Ada", placeholder: nil) == "Ada")
    }

    @Test
    func emptyFieldThatReportsItsPlaceholderHasNoText() {
        #Testing::expect(TextEntry.text(value: "Name", placeholder: "Name") == "")
    }

    @Test
    func fieldWithoutAStringValueHasNoText() {
        #Testing::expect(TextEntry.text(value: nil, placeholder: "Name") == "")
        #Testing::expect(TextEntry.text(value: 3, placeholder: nil) == "")
    }

    @Test
    func emptyValueWithAnEmptyPlaceholderHasNoText() {
        #Testing::expect(TextEntry.text(value: "", placeholder: "") == "")
    }

    @Test
    func deletionHasOneKeyForEachCharacter() {
        #Testing::expect(TextEntry.deletion(of: "Ada") == String(repeating: XCUIKeyboardKey.delete.rawValue, count: 3))
        #Testing::expect(TextEntry.deletion(of: "") == "")
        #Testing::expect(TextEntry.deletion(of: "👩‍💻é") == TextEntry.deletion(of: "ab"))
    }
}
