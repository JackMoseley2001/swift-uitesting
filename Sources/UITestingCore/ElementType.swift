/// A type of element that a UI test can look for.
///
/// The cases have the same names as the cases of XCTest's `XCUIElement.ElementType`.
/// This type exists so that code compiled into the app can name a type of element
/// without depending on XCTest.
public enum ElementType: String, Hashable, Sendable, CaseIterable {
    /// An element of any type.
    case any

    /// An element that XCTest reports with no more specific type, such as a plain container.
    case other

    /// A button.
    case button

    /// Text that the user cannot edit, such as a SwiftUI `Text` or a `UILabel`.
    case staticText

    /// A single-line text field.
    case textField

    /// A text field that hides what is typed, such as a SwiftUI `SecureField`.
    case secureTextField

    /// A multi-line text view, such as a SwiftUI `TextEditor`.
    case textView

    /// A search field.
    case searchField

    /// A switch, such as a SwiftUI `Toggle` on iOS.
    case `switch`

    /// A toggle.
    case toggle

    /// A checkbox, such as a SwiftUI `Toggle` on macOS.
    case checkBox

    /// A radio button.
    case radioButton

    /// A slider.
    case slider

    /// A stepper.
    case stepper

    /// A picker.
    case picker

    /// One wheel of a picker.
    case pickerWheel

    /// A date picker.
    case datePicker

    /// A segmented control.
    case segmentedControl

    /// A pop-up button.
    case popUpButton

    /// A button that shows a menu.
    case menuButton

    /// A menu.
    case menu

    /// An item in a menu.
    case menuItem

    /// An image.
    case image

    /// An icon.
    case icon

    /// A link.
    case link

    /// A cell in a table or collection view.
    case cell

    /// A table, such as a `UITableView`.
    case table

    /// A collection view. On recent versions of iOS, a SwiftUI `List` is one.
    case collectionView

    /// A scroll view.
    case scrollView

    /// A navigation bar.
    case navigationBar

    /// A tab bar.
    case tabBar

    /// A tab.
    case tab

    /// A toolbar.
    case toolbar

    /// An alert.
    case alert

    /// A sheet.
    case sheet

    /// A window.
    case window

    /// A group of elements.
    case group

    /// A web view.
    case webView

    /// A map.
    case map

    /// A progress indicator.
    case progressIndicator

    /// An activity indicator.
    case activityIndicator

    /// A page indicator.
    case pageIndicator

    /// A keyboard.
    case keyboard

    /// A key on a keyboard.
    case key
}
