import UITestingCore

/// Identifiers for the controls example.
enum ControlsID: ElementIDs {
    // A SwiftUI `Toggle` is a switch on iOS and a checkbox on macOS.
    #if os(macOS)
    static var notificationsSwitch: CheckBox { element() }
    #else
    static var notificationsSwitch: Switch { element() }
    #endif
    static var volumeSlider: Slider { element() }
    static var sizePicker: SegmentedPicker { element() }
    static var colourPicker: Picker { element() }
    static var shapeMenu: MenuPicker { element() }
    static var quantityStepper: Stepper { element() }
    static var summary: StaticText { element() }
}
