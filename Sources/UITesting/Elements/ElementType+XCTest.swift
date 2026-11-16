import XCTest

extension XCUIElement.ElementType {
    /// Creates XCTest's element type from the type that identifiers declare.
    init(_ type: UITestingCore.ElementType) {
        switch type {
        case .any: self = .any
        case .other: self = .other
        case .button: self = .button
        case .staticText: self = .staticText
        case .textField: self = .textField
        case .secureTextField: self = .secureTextField
        case .textView: self = .textView
        case .searchField: self = .searchField
        case .switch: self = .switch
        case .toggle: self = .toggle
        case .checkBox: self = .checkBox
        case .radioButton: self = .radioButton
        case .slider: self = .slider
        case .stepper: self = .stepper
        case .picker: self = .picker
        case .pickerWheel: self = .pickerWheel
        case .datePicker: self = .datePicker
        case .segmentedControl: self = .segmentedControl
        case .popUpButton: self = .popUpButton
        case .menuButton: self = .menuButton
        case .menu: self = .menu
        case .menuItem: self = .menuItem
        case .image: self = .image
        case .icon: self = .icon
        case .link: self = .link
        case .cell: self = .cell
        case .table: self = .table
        case .collectionView: self = .collectionView
        case .scrollView: self = .scrollView
        case .navigationBar: self = .navigationBar
        case .tabBar: self = .tabBar
        case .tab: self = .tab
        case .toolbar: self = .toolbar
        case .alert: self = .alert
        case .sheet: self = .sheet
        case .window: self = .window
        case .group: self = .group
        case .webView: self = .webView
        case .map: self = .map
        case .progressIndicator: self = .progressIndicator
        case .activityIndicator: self = .activityIndicator
        case .pageIndicator: self = .pageIndicator
        case .keyboard: self = .keyboard
        case .key: self = .key
        }
    }
}
