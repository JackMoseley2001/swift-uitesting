import SwiftUI
import UITestingCore

/// A list whose rows are identified by the item they show, so that a UI test can pick
/// out the row for a particular item.
struct FruitList: View {
    @State private var selection: Fruit?

    var body: some View {
        VStack(spacing: 8) {
            Text(selection.map { "Selected \($0.name)" } ?? "Nothing selected")
                .accessibilityIdentifier(FruitID.selection)

            ForEach(Fruit.all) { fruit in
                Button(fruit.name) {
                    selection = fruit
                }
                .accessibilityIdentifier(FruitID.row(fruit.id))
            }
        }
    }
}
