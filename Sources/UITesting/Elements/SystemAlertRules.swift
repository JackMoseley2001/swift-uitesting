/// How to answer a system alert.
public enum SystemAlertAnswer: Sendable, Equatable {
    /// Give the app what it asked for.
    ///
    /// This is for alerts that say which of their buttons allows. See ``SystemAlert``
    /// for the ones that do.
    case allow

    /// Refuse what the app asked for.
    ///
    /// This is for alerts that say which of their buttons refuses. See ``SystemAlert``
    /// for the ones that do.
    case deny

    /// Tap the button with a label, such as "Allow While Using App".
    ///
    /// This is for any alert that has a button with this label.
    case button(String)

    /// The button that gives this answer.
    var button: SystemAlertButton {
        switch self {
        case .allow: .allow
        case .deny: .deny
        case .button(let label): .label(label)
        }
    }
}

/// An answer, and the alerts it is for.
struct SystemAlertRule: Equatable, Sendable {
    var answer: SystemAlertAnswer

    /// The names the system gives the permissions this rule is for, such as
    /// "kTCCServiceMicrophone". Empty if the rule is for every alert.
    var services: [String] = []

    /// Whether the rule is for an alert with an identifier such as "kTCCServiceMicrophone-alert".
    func isFor(alertWithIdentifier identifier: String) -> Bool {
        services.isEmpty || services.contains { identifier.hasPrefix("\($0)-") }
    }
}

/// The answers that a test's traits give to system alerts.
struct SystemAlertRules: Equatable, Sendable {
    /// The rules in the order the traits gave them, the suite's first.
    var rules: [SystemAlertRule]

    /// Returns the position of the button to tap in an alert, or `nil` if no rule answers it.
    ///
    /// The last rule that is for the alert, and whose button the alert has, decides.
    /// So a test can override its suite, and a rule for a label does not get in the
    /// way of alerts without that label.
    func positionOfButton(
        inAlertWithIdentifier identifier: String,
        buttons: [SystemAlertButtonInfo]
    ) -> Int? {
        for rule in rules.reversed() where rule.isFor(alertWithIdentifier: identifier) {
            let choice = SystemAlertChoice.position(of: rule.answer.button, inAlertTitled: "", withButtons: buttons)
            if case .success(let position) = choice {
                return position
            }
        }
        return nil
    }
}
