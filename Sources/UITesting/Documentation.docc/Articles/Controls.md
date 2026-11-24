# Controls and date pickers

Set switches, sliders, steppers, pickers and date pickers, and read what they hold.

## Overview

Identifiers declared as these kinds have actions of their own. Each waits for the
element to exist and be enabled, like `tap()`.

```swift
try app[SettingsID.notificationsSwitch].setOn(true)
try app[PlayerID.volumeSlider].adjust(to: 0.8)
try app[BasketID.quantityStepper].increment(times: 2)
try app[SettingsID.sizePicker].select("Large")
try app[SettingsID.themePicker].select("Dark")
try app[ProfileID.countryPicker].select("France")
```

| Kind | Members | Why not XCTest's own |
|---|---|---|
| `Switch`, `Toggle`, `CheckBox` | `isOn`, `setOn(_:)`, `toggle()` | `XCUIElement` reports the state as the string `"1"` or `"0"`. `setOn(_:)` does nothing if the switch is already in that state, and checks that it changed. |
| `Slider` | `position`, `adjust(to:tolerance:)` | `adjust(toNormalizedSliderPosition:)` can land several percent away. This drags the thumb, reads where it landed and drags again, until it is within the tolerance, which is 0.02 unless you pass one. |
| `Stepper` | `value`, `increment(times:)`, `decrement(times:)` | Finds the two halves of the stepper, which have no identifiers of their own to look up. If the stepper reports a value, each step is checked, so a step past the end of its range fails. Pass `requiringChange: false` when a step is allowed to change nothing. `value` is the stepper's value as text, which `XCUIElement` reports as a string on iOS and as a number on macOS. |
| `SegmentedControl`, `SegmentedPicker`, `RadioGroup` | `selection`, `select(_:)` | Finds the segment by its label, and the failure lists the segments if there is none. `SegmentedPicker` is a SwiftUI `Picker` with the `segmented` style, which is a segmented control on iOS and a group of radio buttons on macOS. |
| `MenuPicker` | `selection`, `select(_:)` | For a SwiftUI `Picker` with the `menu` style, or a `Menu`. The options are not inside the control, because the menu is shown over the app. This opens the menu, waits for the option and taps it. The kind matches a button on iOS and a pop-up button on macOS, which is how XCTest reports the control on each. |
| `Picker`, `PickerWheel` (iOS) | `selection()`, `select(_:)` | Finds the wheel inside a picker that has the identifier. Pass `inWheel:` for a picker with several wheels. |

Positions of a slider run from 0 at its start to 1 at its end.

## Date pickers

Identifiers declared as `DatePicker` can be set to a date or a time, on iOS:

```swift
try app[BookingID.datePicker].setDate(year: 2026, month: 3, day: 9)
try app[BookingID.timePicker].setTime(hour: 14, minute: 30)
```

A date picker is several controls, and which ones depends on its style. These actions
open the calendar or the wheels if they have to, set them, check where they ended up
and close them again.

| Style | `setDate` | `setTime` |
|---|---|---|
| `compact`, the default | Yes | Yes |
| `graphical` | Yes | No |
| `wheel` | Yes | Yes |

- **The hour is from 0 to 23**, whether or not the picker shows AM and PM.
- **The month and AM or PM are found by name**, in the language of the device. If the
  test launches the app in another language, pass it:
  `setDate(year: 2026, month: 3, day: 9, locale: Locale(identifier: "fr"))`.
- **A date outside the picker's range** fails, because its day cannot be selected.
- **A `wheel` picker that shows a date and a time** has one wheel for the day, such as
  "Tue, Nov 14", in place of a month, a day and a year. `setDate` fails for it, and
  says so, because XCTest can only turn that wheel where a day is written as the
  United States writes it. `setTime` works on it. To set both, use a picker that shows
  a calendar, or one with wheels for a date beside one for a time.

## Topics

### Switches

- ``UITestElement/isOn``
- ``UITestElement/setOn(_:within:filePath:line:)``
- ``UITestElement/toggle(within:filePath:line:)``

### Sliders and steppers

- ``UITestElement/position``
- ``UITestElement/adjust(to:tolerance:within:filePath:line:)``
- ``UITestElement/value``
- ``UITestElement/increment(times:requiringChange:within:filePath:line:)``
- ``UITestElement/decrement(times:requiringChange:within:filePath:line:)``

### Date pickers

- ``UITestElement/setDate(year:month:day:locale:within:filePath:line:)``
- ``UITestElement/setTime(hour:minute:locale:within:filePath:line:)``
