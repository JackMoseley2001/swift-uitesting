import SwiftUI
import UITestingCore

/// A screen with text that is too faint to read easily, which an accessibility audit
/// finds, beside text and a button that it has nothing to say about.
///
/// The note and the tags are nearly the colour of what is behind them. Everything
/// else has the colours and the sizes that the system gives it.
struct AuditView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Review your order")
                    .font(.title)
                    .accessibilityIdentifier(AuditID.title)

                Text("Prices include tax")
                    .foregroundStyle(Self.faint)
                    .accessibilityIdentifier(AuditID.faintNote)

                HStack(spacing: 16) {
                    ForEach(1...2, id: \.self) { number in
                        Text("Tag \(number)")
                            .foregroundStyle(Self.faint)
                            .accessibilityIdentifier(AuditID.tag(number))
                    }
                }

                Button("Save") {}
                    // The colour the system gives a button is itself a little too
                    // light on white for the audit.
                    .tint(.black)
                    .accessibilityIdentifier(AuditID.saveButton)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .background(.white)
        .environment(\.colorScheme, .light)
    }

    /// A grey that is close to the white behind it.
    private static let faint = Color(white: 0.85)
}
