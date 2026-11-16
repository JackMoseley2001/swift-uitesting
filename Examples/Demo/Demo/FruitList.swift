import SwiftUI
import UITestingCore

/// A list whose rows are identified by the item they show, so that a UI test can pick
/// out the row for a particular item.
struct FruitList: View {
    @State private var selection: Fruit?
    @State private var canClear = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text(selection.map { "Selected \($0.name)" } ?? "Nothing selected")
                    .accessibilityIdentifier(FruitID.selection)

                ForEach(Fruit.all) { fruit in
                    Button(fruit.name) {
                        selection = fruit
                    }
                    .accessibilityIdentifier(FruitID.row(fruit.id))
                }

                // Stays disabled for a moment after a selection, so that UI tests have to
                // wait for it before they can tap it.
                Button("Clear selection") {
                    selection = nil
                }
                .disabled(!canClear)
                .accessibilityIdentifier(FruitID.clearButton)
            }
            .task(id: selection) {
                canClear = false
                guard selection != nil else { return }
                try? await Task.sleep(for: .seconds(1))
                canClear = !Task.isCancelled
            }
            .padding()
        }
    }
}
