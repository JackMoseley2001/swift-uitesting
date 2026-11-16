import SwiftUI
import UITestingCore

/// A form with a text field, a secure field and a multi-line editor, and a line of
/// text that shows what they hold, so that UI tests can check what they typed.
struct ProfileForm: View {
    @State private var name = "Ada Lovelace"
    @State private var password = ""
    @State private var notes = "First line\nSecond line"

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier(ProfileID.nameField)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier(ProfileID.passwordField)

                TextEditor(text: $notes)
                    .frame(height: 80)
                    .border(.separator)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier(ProfileID.notesField)

                Text("\(name)|\(password)|\(notes)")
                    .font(.footnote)
                    .accessibilityIdentifier(ProfileID.summary)
            }
            .padding()
        }
        // Lets a drag put the keyboard away, which is how UI tests dismiss it after
        // typing into the multi-line editor.
        .scrollDismissesKeyboard(.immediately)
    }
}
