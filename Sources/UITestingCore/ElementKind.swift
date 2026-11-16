/// A kind of element that an ``ElementID`` identifies.
///
/// The kinds that come with the package are in ``ElementKinds``, one for each
/// ``ElementType``. You do not normally need another, but you can add one by
/// conforming a type of your own.
public protocol ElementKind {
    /// The type of element that a UI test looks for.
    static var elementType: ElementType { get }
}

/// The kinds of element that come with the package.
///
/// Inside an ``ElementIDs`` group, each kind's identifier type is available under the
/// kind's own name, so you write `Button` and not `ElementID<ElementKinds.Button>`.
public enum ElementKinds {
    /// An element of any type.
    public enum AnyElement: ElementKind {
        public static var elementType: ElementType { .any }
    }

    /// An element that XCTest reports with no more specific type, such as a plain container.
    public enum Other: ElementKind {
        public static var elementType: ElementType { .other }
    }

    /// A button.
    public enum Button: ElementKind {
        public static var elementType: ElementType { .button }
    }

    /// Text that the user cannot edit, such as a SwiftUI `Text` or a `UILabel`.
    public enum StaticText: ElementKind {
        public static var elementType: ElementType { .staticText }
    }

    /// A single-line text field.
    public enum TextField: ElementKind {
        public static var elementType: ElementType { .textField }
    }

    /// A text field that hides what is typed, such as a SwiftUI `SecureField`.
    public enum SecureTextField: ElementKind {
        public static var elementType: ElementType { .secureTextField }
    }

    /// A multi-line text view, such as a SwiftUI `TextEditor`.
    public enum TextView: ElementKind {
        public static var elementType: ElementType { .textView }
    }

    /// A search field.
    public enum SearchField: ElementKind {
        public static var elementType: ElementType { .searchField }
    }

    /// A switch, such as a SwiftUI `Toggle` on iOS.
    public enum Switch: ElementKind {
        public static var elementType: ElementType { .switch }
    }

    /// A toggle.
    public enum Toggle: ElementKind {
        public static var elementType: ElementType { .toggle }
    }

    /// A checkbox, such as a SwiftUI `Toggle` on macOS.
    public enum CheckBox: ElementKind {
        public static var elementType: ElementType { .checkBox }
    }

    /// A radio button.
    public enum RadioButton: ElementKind {
        public static var elementType: ElementType { .radioButton }
    }

    /// A slider.
    public enum Slider: ElementKind {
        public static var elementType: ElementType { .slider }
    }

    /// A stepper.
    public enum Stepper: ElementKind {
        public static var elementType: ElementType { .stepper }
    }

    /// A picker.
    public enum Picker: ElementKind {
        public static var elementType: ElementType { .picker }
    }

    /// One wheel of a picker.
    public enum PickerWheel: ElementKind {
        public static var elementType: ElementType { .pickerWheel }
    }

    /// A date picker.
    public enum DatePicker: ElementKind {
        public static var elementType: ElementType { .datePicker }
    }

    /// A segmented control.
    public enum SegmentedControl: ElementKind {
        public static var elementType: ElementType { .segmentedControl }
    }

    /// A pop-up button.
    public enum PopUpButton: ElementKind {
        public static var elementType: ElementType { .popUpButton }
    }

    /// A button that shows a menu.
    public enum MenuButton: ElementKind {
        public static var elementType: ElementType { .menuButton }
    }

    /// A menu.
    public enum Menu: ElementKind {
        public static var elementType: ElementType { .menu }
    }

    /// An item in a menu.
    public enum MenuItem: ElementKind {
        public static var elementType: ElementType { .menuItem }
    }

    /// An image.
    public enum Image: ElementKind {
        public static var elementType: ElementType { .image }
    }

    /// An icon.
    public enum Icon: ElementKind {
        public static var elementType: ElementType { .icon }
    }

    /// A link.
    public enum Link: ElementKind {
        public static var elementType: ElementType { .link }
    }

    /// A cell in a table or collection view.
    public enum Cell: ElementKind {
        public static var elementType: ElementType { .cell }
    }

    /// A table, such as a `UITableView`.
    public enum Table: ElementKind {
        public static var elementType: ElementType { .table }
    }

    /// A collection view. On recent versions of iOS, a SwiftUI `List` is one.
    public enum CollectionView: ElementKind {
        public static var elementType: ElementType { .collectionView }
    }

    /// A scroll view.
    public enum ScrollView: ElementKind {
        public static var elementType: ElementType { .scrollView }
    }

    /// A navigation bar.
    public enum NavigationBar: ElementKind {
        public static var elementType: ElementType { .navigationBar }
    }

    /// A tab bar.
    public enum TabBar: ElementKind {
        public static var elementType: ElementType { .tabBar }
    }

    /// A tab.
    public enum Tab: ElementKind {
        public static var elementType: ElementType { .tab }
    }

    /// A toolbar.
    public enum Toolbar: ElementKind {
        public static var elementType: ElementType { .toolbar }
    }

    /// An alert.
    public enum Alert: ElementKind {
        public static var elementType: ElementType { .alert }
    }

    /// A sheet.
    public enum Sheet: ElementKind {
        public static var elementType: ElementType { .sheet }
    }

    /// A window.
    public enum Window: ElementKind {
        public static var elementType: ElementType { .window }
    }

    /// A group of elements.
    public enum Group: ElementKind {
        public static var elementType: ElementType { .group }
    }

    /// A web view.
    public enum WebView: ElementKind {
        public static var elementType: ElementType { .webView }
    }

    /// A map.
    public enum Map: ElementKind {
        public static var elementType: ElementType { .map }
    }

    /// A progress indicator.
    public enum ProgressIndicator: ElementKind {
        public static var elementType: ElementType { .progressIndicator }
    }

    /// An activity indicator.
    public enum ActivityIndicator: ElementKind {
        public static var elementType: ElementType { .activityIndicator }
    }

    /// A page indicator.
    public enum PageIndicator: ElementKind {
        public static var elementType: ElementType { .pageIndicator }
    }

    /// A keyboard.
    public enum Keyboard: ElementKind {
        public static var elementType: ElementType { .keyboard }
    }

    /// A key on a keyboard.
    public enum Key: ElementKind {
        public static var elementType: ElementType { .key }
    }
}

extension ElementIDs {
    /// The type of an identifier for an element of any type.
    public typealias AnyElement = ElementID<ElementKinds.AnyElement>

    /// The type of an identifier for an element that XCTest reports with no more specific type,
    /// such as a plain container.
    public typealias Other = ElementID<ElementKinds.Other>

    /// The type of an identifier for a button.
    public typealias Button = ElementID<ElementKinds.Button>

    /// The type of an identifier for text that the user cannot edit, such as a SwiftUI `Text` or a `UILabel`.
    public typealias StaticText = ElementID<ElementKinds.StaticText>

    /// The type of an identifier for a single-line text field.
    public typealias TextField = ElementID<ElementKinds.TextField>

    /// The type of an identifier for a text field that hides what is typed, such as a SwiftUI `SecureField`.
    public typealias SecureTextField = ElementID<ElementKinds.SecureTextField>

    /// The type of an identifier for a multi-line text view, such as a SwiftUI `TextEditor`.
    public typealias TextView = ElementID<ElementKinds.TextView>

    /// The type of an identifier for a search field.
    public typealias SearchField = ElementID<ElementKinds.SearchField>

    /// The type of an identifier for a switch, such as a SwiftUI `Toggle` on iOS.
    public typealias Switch = ElementID<ElementKinds.Switch>

    /// The type of an identifier for a toggle.
    public typealias Toggle = ElementID<ElementKinds.Toggle>

    /// The type of an identifier for a checkbox, such as a SwiftUI `Toggle` on macOS.
    public typealias CheckBox = ElementID<ElementKinds.CheckBox>

    /// The type of an identifier for a radio button.
    public typealias RadioButton = ElementID<ElementKinds.RadioButton>

    /// The type of an identifier for a slider.
    public typealias Slider = ElementID<ElementKinds.Slider>

    /// The type of an identifier for a stepper.
    public typealias Stepper = ElementID<ElementKinds.Stepper>

    /// The type of an identifier for a picker.
    public typealias Picker = ElementID<ElementKinds.Picker>

    /// The type of an identifier for one wheel of a picker.
    public typealias PickerWheel = ElementID<ElementKinds.PickerWheel>

    /// The type of an identifier for a date picker.
    public typealias DatePicker = ElementID<ElementKinds.DatePicker>

    /// The type of an identifier for a segmented control.
    public typealias SegmentedControl = ElementID<ElementKinds.SegmentedControl>

    /// The type of an identifier for a pop-up button.
    public typealias PopUpButton = ElementID<ElementKinds.PopUpButton>

    /// The type of an identifier for a button that shows a menu.
    public typealias MenuButton = ElementID<ElementKinds.MenuButton>

    /// The type of an identifier for a menu.
    public typealias Menu = ElementID<ElementKinds.Menu>

    /// The type of an identifier for an item in a menu.
    public typealias MenuItem = ElementID<ElementKinds.MenuItem>

    /// The type of an identifier for an image.
    public typealias Image = ElementID<ElementKinds.Image>

    /// The type of an identifier for an icon.
    public typealias Icon = ElementID<ElementKinds.Icon>

    /// The type of an identifier for a link.
    public typealias Link = ElementID<ElementKinds.Link>

    /// The type of an identifier for a cell in a table or collection view.
    public typealias Cell = ElementID<ElementKinds.Cell>

    /// The type of an identifier for a table, such as a `UITableView`.
    public typealias Table = ElementID<ElementKinds.Table>

    /// The type of an identifier for a collection view. On recent versions of iOS, a SwiftUI `List` is one.
    public typealias CollectionView = ElementID<ElementKinds.CollectionView>

    /// The type of an identifier for a scroll view.
    public typealias ScrollView = ElementID<ElementKinds.ScrollView>

    /// The type of an identifier for a navigation bar.
    public typealias NavigationBar = ElementID<ElementKinds.NavigationBar>

    /// The type of an identifier for a tab bar.
    public typealias TabBar = ElementID<ElementKinds.TabBar>

    /// The type of an identifier for a tab.
    public typealias Tab = ElementID<ElementKinds.Tab>

    /// The type of an identifier for a toolbar.
    public typealias Toolbar = ElementID<ElementKinds.Toolbar>

    /// The type of an identifier for an alert.
    public typealias Alert = ElementID<ElementKinds.Alert>

    /// The type of an identifier for a sheet.
    public typealias Sheet = ElementID<ElementKinds.Sheet>

    /// The type of an identifier for a window.
    public typealias Window = ElementID<ElementKinds.Window>

    /// The type of an identifier for a group of elements.
    public typealias Group = ElementID<ElementKinds.Group>

    /// The type of an identifier for a web view.
    public typealias WebView = ElementID<ElementKinds.WebView>

    /// The type of an identifier for a map.
    public typealias Map = ElementID<ElementKinds.Map>

    /// The type of an identifier for a progress indicator.
    public typealias ProgressIndicator = ElementID<ElementKinds.ProgressIndicator>

    /// The type of an identifier for an activity indicator.
    public typealias ActivityIndicator = ElementID<ElementKinds.ActivityIndicator>

    /// The type of an identifier for a page indicator.
    public typealias PageIndicator = ElementID<ElementKinds.PageIndicator>

    /// The type of an identifier for a keyboard.
    public typealias Keyboard = ElementID<ElementKinds.Keyboard>

    /// The type of an identifier for a key on a keyboard.
    public typealias Key = ElementID<ElementKinds.Key>
}

/// A kind of element that text can be typed into.
///
/// In a UI test, elements of these kinds have actions for entering, replacing and
/// clearing text.
public protocol TextEntryKind: ElementKind {}

/// A kind of element that holds one line of text, where the Return key submits the
/// text and does not start a new line.
public protocol SingleLineTextEntryKind: TextEntryKind {}

extension ElementKinds.TextField: SingleLineTextEntryKind {}
extension ElementKinds.SecureTextField: SingleLineTextEntryKind {}
extension ElementKinds.SearchField: SingleLineTextEntryKind {}
extension ElementKinds.TextView: TextEntryKind {}

/// A kind of element that is either on or off.
///
/// In a UI test, elements of these kinds have actions for reading and setting that state.
public protocol SwitchKind: ElementKind {}

extension ElementKinds.Switch: SwitchKind {}
extension ElementKinds.Toggle: SwitchKind {}

/// A kind of element that holds a wheel to pick a value from.
///
/// In a UI test, elements of these kinds have an action for picking a value.
public protocol PickerWheelKind: ElementKind {}

extension ElementKinds.Picker: PickerWheelKind {}
extension ElementKinds.PickerWheel: PickerWheelKind {}
