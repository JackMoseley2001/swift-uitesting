import SwiftUI

/// A screen whose elements have no accessibility identifiers, as in a web view or a
/// screen that another library shows, so that UI tests find them by their labels.
///
/// It has a line of text, a field and a button that is disabled until the field
/// holds something, and two addresses that each have a button labelled "Remove".
struct LabelsView: View {
    @State private var email = ""
    @State private var signedInAs: String?
    @State private var addresses = Address.all

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(signedInAs.map { "Signed in as \($0)" } ?? "Welcome back")

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
                    // The label is what a test finds the field by. It is set here so that
                    // it does not depend on how SwiftUI describes a field that shows
                    // only a placeholder.
                    .accessibilityLabel("Email")

                Button("Continue") { signedInAs = email }
                    .disabled(email.isEmpty)

                ForEach(addresses) { address in
                    VStack(spacing: 4) {
                        Text(address.street)
                        Button("Remove") {
                            addresses.removeAll { $0 == address }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                    // Makes the address an element of its own that holds the text and
                    // the button, so that a test can look inside it.
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(address.label)
                }
            }
            .padding()
        }
    }
}

/// An address on the labels example.
private struct Address: Identifiable, Equatable {
    static let all = [
        Address(name: "Home", street: "1 Orchard Lane"),
        Address(name: "Work", street: "2 Station Road"),
    ]

    let name: String
    let street: String

    var id: String { name }

    /// What a test finds the address by.
    var label: String { "\(name) address" }
}
