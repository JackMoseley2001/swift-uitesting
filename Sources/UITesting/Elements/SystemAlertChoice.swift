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

    /// One button, or another if the alert does not have the first. This is how a
    /// test falls back on a label or a position where an alert does not say which of
    /// its buttons allows.
    indirect case either(Self, or: Self)

    /// How the button is named in a message, such as `"Allow"` or `button 1`.
    var description: String {
        switch self {
        case .label(let label): "\"\(label)\""
        case .index(let index): "button \(index)"
        case .allow: "the button that allows"
        case .deny: "the button that refuses"
        case .either(let first, or: let second): "\(first.description), or \(second.description)"
        }
    }

    /// The end of the accessibility identifier that the system gives the button, for
    /// the buttons that are found by it.
    var identifierSuffix: String? {
        switch self {
        case .allow: "-allow-button"
        case .deny: "-deny-button"
        case .label, .index, .either: nil
        }
    }

    /// Whether this is the button that allows or refuses with nothing to fall back
    /// on, which only an alert that marks its buttons has.
    var needsMarkedButtons: Bool {
        self == .allow || self == .deny
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

    /// Whether the system marks its alerts and their buttons with identifiers. It does
    /// from iOS 27. Before that an alert says nothing about what it asks for, or about
    /// which of its buttons allows.
    static var systemMarksAlerts: Bool {
        if #available(iOS 27, *) { true } else { false }
    }

    /// What a failure says about a system that does not mark the buttons of its alerts.
    static let unmarkedAdvice =
        "Before iOS 27 no alert says which button allows or refuses. Give a label or a position to fall back "
        + "on, as in allow(orTap: \"Allow\"), or check for iOS 27 with #available and tap a button otherwise"

    /// Returns the position of the button, or a description of why the alert has no such button.
    ///
    /// - Parameters:
    ///   - button: The button the test asked for.
    ///   - title: The title of the alert, used in the description of a failure.
    ///   - buttons: The alert's buttons, in order.
    ///   - noun: What to call the alert in the description of a failure.
    ///   - marked: Whether the system marks the buttons that allow and refuse with
    ///     identifiers. If it does not, a failure to find one of them says so.
    static func position(
        of button: SystemAlertButton,
        inAlertTitled title: String,
        withButtons buttons: [SystemAlertButtonInfo],
        noun: AlertNoun = .systemAlert,
        marked: Bool = systemMarksAlerts
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

            case .either(let first, or: let second):
                [first, second].lazy
                    .compactMap { choice -> Int? in
                        let found = Self.position(
                            of: choice,
                            inAlertTitled: title,
                            withButtons: buttons,
                            noun: noun,
                            marked: marked
                        )
                        return try? found.get()
                    }
                    .first
            }
        if let position {
            return .success(position)
        }

        let reason =
            switch button {
            case .label: "the \(noun.short) has no button with this label"
            case .index: "the \(noun.short) has \(buttons.count) \(buttons.count == 1 ? "button" : "buttons")"
            case .allow, .deny: "the \(noun.short) does not say which of its buttons that is"
            case .either: "the \(noun.short) has neither"
            }
        let listed = buttons.map { "\"\($0.label)\"" }.joined(separator: ", ")
        let advice = button.needsMarkedButtons && !marked ? ". \(unmarkedAdvice)" : ""
        return .failure(
            SystemAlertChoiceError(
                message: "Could not tap \(button.description) in the \(noun.full) \"\(title)\": \(reason). "
                    + "Its buttons are: \(listed)\(advice)"
            )
        )
    }

    /// Describes a system alert that did not appear.
    static func noAlert(
        inOrderTo intent: String,
        after timeout: Duration,
        noun: AlertNoun = .systemAlert
    ) -> String {
        "Could not \(intent): no \(noun.full) appeared within \(ExpectationFailure.describe(timeout))"
    }

    /// Describes a system alert that did not go away.
    static func alertStayed(
        titled title: String,
        after timeout: Duration,
        noun: AlertNoun = .systemAlert
    ) -> String {
        "The \(noun.full) \"\(title)\" was still showing after \(ExpectationFailure.describe(timeout))"
    }
}

/// What to call an alert in the description of a failure.
struct AlertNoun: Equatable, Sendable {
    /// The name in full, such as "system alert".
    var full: String

    /// The name for a second mention, such as "alert".
    var short: String

    /// An alert that the system shows over the app.
    static let systemAlert = Self(full: "system alert", short: "alert")

    /// An alert that the app presents.
    static let alert = Self(full: "alert", short: "alert")

    /// A confirmation dialog or action sheet that the app presents.
    static let dialog = Self(full: "dialog", short: "dialog")
}

/// Why a system alert has no button that a test asked for.
struct SystemAlertChoiceError: Error, Equatable, CustomStringConvertible {
    var message: String

    var description: String { message }
}
