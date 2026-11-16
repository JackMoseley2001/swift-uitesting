import SwiftUI
import UITestingCore

/// A long list that only creates the rows near the ones on screen, so that UI tests
/// have to scroll to a row before they can use it.
struct NumberList: View {
    static let count = 60

    @State private var selection: Int?

    var body: some View {
        VStack(spacing: 8) {
            Text(selection.map { "Selected \($0)" } ?? "No number selected")
                .accessibilityIdentifier(NumberID.selection)

            LazyVStack(spacing: 8) {
                ForEach(1...Self.count, id: \.self) { number in
                    Button("Number \(number)") {
                        selection = number
                    }
                    .frame(height: 36)
                    .accessibilityIdentifier(NumberID.row(number))
                }
            }
        }
    }
}
