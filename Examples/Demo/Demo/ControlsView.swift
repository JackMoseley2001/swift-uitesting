import SwiftUI
import UITestingCore

/// A switch, a slider, three pickers and a stepper, and a line of text that shows what they are set to.
struct ControlsView: View {
    static let sizes = ["Small", "Medium", "Large"]
    static let shapes = ["Circle", "Square", "Triangle"]
    static let colours = ["Red", "Green", "Blue", "Yellow"]

    @State private var notifications = false
    @State private var volume = 0.5
    @State private var size = "Medium"
    @State private var colour = "Green"
    @State private var quantity = 2
    @State private var shape = "Circle"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Toggle("Notifications", isOn: $notifications)
                    .accessibilityIdentifier(ControlsID.notificationsSwitch)

                Slider(value: $volume)
                    .accessibilityIdentifier(ControlsID.volumeSlider)

                Picker("Size", selection: $size) {
                    ForEach(Self.sizes, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier(ControlsID.sizePicker)

                // Only iOS has pickers with a wheel.
                #if os(iOS)
                Picker("Colour", selection: $colour) {
                    ForEach(Self.colours, id: \.self) { Text($0) }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .accessibilityIdentifier(ControlsID.colourPicker)
                #endif

                Picker("Shape", selection: $shape) {
                    ForEach(Self.shapes, id: \.self) { Text($0) }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier(ControlsID.shapeMenu)

                Stepper("Quantity \(quantity)", value: $quantity, in: 0...5)
                    .accessibilityIdentifier(ControlsID.quantityStepper)

                Text("\(notifications ? "on" : "off")|\(Int((volume * 100).rounded()))|\(size)|\(colour)")
                    .font(.footnote)
                    .accessibilityIdentifier(ControlsID.summary)
            }
            .padding()
        }
    }
}
