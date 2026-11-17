/// Which button of a system alert to tap.
enum SystemAlertButton: Equatable, Sendable {
    /// The button with a label.
    case label(String)

    /// The button at a position, counting from 0 in the order the alert lists them.
    case index(Int)

    /// The button that gives the app what it asked for.
    case allow

    /// The button that refuses what the app asked for.
    case deny

    /// How the button is named in a message, such as `"Allow"` or `button 1`.
    var description: String {
        switch self {
        case .label(let label): "\"\(label)\""
        case .index(let index): "button \(index)"
        case .allow: "the button that allows"
        case .deny: "the button that refuses"
        }
    }

    /// The end of the accessibility identifier that the system gives the button, for
    /// the buttons that are found by it.
    var identifierSuffix: String? {
        switch self {
        case .allow: "-allow-button"
        case .deny: "-deny-button"
        case .label, .index: nil
        }
    }
}

/// What a system alert says about one of its buttons.
struct SystemAlertButtonInfo: Equatable, Sendable {
    var label: String
    var identifier: String = ""
}

/// Finds the button of a system alert that a test asked for.
enum SystemAlertChoice {
    /// Returns the positions of the buttons to keep, leaving out repeats.
    ///
    /// The system's alerts report each button twice, one inside the other. A button is
    /// a repeat if an earlier one has the same label and identifier.
    static func positionsWithoutRepeats(in buttons: [SystemAlertButtonInfo]) -> [Int] {
        buttons.indices.filter { !buttons[..<$0].contains(buttons[$0]) }
    }

    /// Returns the position of the button, or a description of why the alert has no such button.
    ///
    /// - Parameters:
    ///   - button: The button the test asked for.
    ///   - title: The title of the alert, used in the description of a failure.
    ///   - buttons: The alert's buttons, in order.
    static func position(
        of button: SystemAlertButton,
        inAlertTitled title: String,
        withButtons buttons: [SystemAlertButtonInfo]
    ) -> Result<Int, SystemAlertChoiceError> {
        let position: Int? =
            switch button {
            case .label(let label):
                buttons.firstIndex { $0.label == label }
            case .index(let index):
                buttons.indices.contains(index) ? index : nil
            case .allow, .deny:
                button.identifierSuffix.flatMap { suffix in
                    buttons.firstIndex { $0.identifier.hasSuffix(suffix) }
                }
            }
        if let position {
            return .success(position)
        }

        let reason =
            switch button {
            case .label: "the alert has no button with this label"
            case .index: "the alert has \(buttons.count) \(buttons.count == 1 ? "button" : "buttons")"
            case .allow, .deny: "the alert does not say which of its buttons that is"
            }
        let listed = buttons.map { "\"\($0.label)\"" }.joined(separator: ", ")
        return .failure(
            SystemAlertChoiceError(
                message: "Could not tap \(button.description) in the system alert \"\(title)\": \(reason). "
                    + "Its buttons are: \(listed)"
            )
        )
    }

    /// Describes a system alert that did not appear.
    static func noAlert(inOrderTo intent: String, after timeout: Duration) -> String {
        "Could not \(intent): no system alert appeared within \(ExpectationFailure.describe(timeout))"
    }

    /// Describes a system alert that did not go away.
    static func alertStayed(titled title: String, after timeout: Duration) -> String {
        "The system alert \"\(title)\" was still showing after \(ExpectationFailure.describe(timeout))"
    }
}

/// Why a system alert has no button that a test asked for.
struct SystemAlertChoiceError: Error, Equatable {
    var message: String
}
