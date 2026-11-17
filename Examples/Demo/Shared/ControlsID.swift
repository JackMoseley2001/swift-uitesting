import UITestingCore

/// Identifiers for the controls example.
enum ControlsID: ElementIDs {
    static var notificationsSwitch: Switch { element() }
    static var volumeSlider: Slider { element() }
    static var sizePicker: SegmentedControl { element() }
    static var colourPicker: Picker { element() }
    static var shapeMenu: MenuPicker { element() }
    static var quantityStepper: Stepper { element() }
    static var summary: StaticText { element() }
}
