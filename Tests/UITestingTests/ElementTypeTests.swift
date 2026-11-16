import Testing
import XCTest

@testable import UITesting

@Suite
struct ElementTypeTests {
    @Test
    func commonElementTypesBecomeTheXCTestTypeOfTheSameName() {
        #Testing::expect(XCUIElement.ElementType(.any) == .any)
        #Testing::expect(XCUIElement.ElementType(.button) == .button)
        #Testing::expect(XCUIElement.ElementType(.staticText) == .staticText)
        #Testing::expect(XCUIElement.ElementType(.textField) == .textField)
        #Testing::expect(XCUIElement.ElementType(.secureTextField) == .secureTextField)
        #Testing::expect(XCUIElement.ElementType(.switch) == .switch)
        #Testing::expect(XCUIElement.ElementType(.picker) == .picker)
        #Testing::expect(XCUIElement.ElementType(.cell) == .cell)
    }

    @Test
    func everyElementTypeBecomesADifferentXCTestType() {
        let types = UITestingCore.ElementType.allCases.map { XCUIElement.ElementType($0).rawValue }

        #Testing::expect(Set(types).count == UITestingCore.ElementType.allCases.count)
    }
}
