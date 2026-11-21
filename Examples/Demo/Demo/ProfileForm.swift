import SwiftUI
import UITestingCore

/// A form with a text field, a secure field and a multi-line editor, and a line of
/// text that shows what they hold, so that UI tests can check what they typed.
struct ProfileForm: View {
    @State private var name = "Ada Lovelace"
    @State private var password = ""
    @State private var notes = "First line\nSecond line"

    @State private var submittedName: String?

    @FocusState private var isEditing: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                TextField("Name", text: $name)
                    #if !os(watchOS) && !os(tvOS)
                    .textFieldStyle(.roundedBorder)
                    #endif
                    .autocorrectionDisabled()
                    .onSubmit { submittedName = name }
                    .accessibilityIdentifier(ProfileID.nameField)

                SecureField("Password", text: $password)
                    #if !os(watchOS) && !os(tvOS)
                    .textFieldStyle(.roundedBorder)
                    #endif
                    .accessibilityIdentifier(ProfileID.passwordField)

                // watchOS and tvOS have no editor for several lines of text.
                #if !os(watchOS) && !os(tvOS)
                TextEditor(text: $notes)
                    .frame(height: 80)
                    .border(.quaternary)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier(ProfileID.notesField)
                #endif

                Text("\(name)|\(password)|\(notes)")
                    .font(.footnote)
                    .accessibilityIdentifier(ProfileID.summary)

                if let submittedName {
                    Text("Submitted \(submittedName)")
                        .font(.footnote)
                        .accessibilityIdentifier(ProfileID.submittedName)
                }
            }
            .padding()
        }
        .focused($isEditing)
        // Only iOS shows a keyboard on the screen with a bar above it.
        #if os(iOS)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Hide keyboard", systemImage: "keyboard.chevron.compact.down.fill") {
                    isEditing = false
                }
                .accessibilityIdentifier(ProfileID.hideKeyboardButton)
            }
        }
        #endif
    }
}
