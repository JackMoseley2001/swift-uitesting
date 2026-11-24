/// How to answer a system alert.
///
/// `.allow` and `.deny` find their button by an identifier, which the system gives it
/// from iOS 27. Before that no alert says which of its buttons allows, so give a label
/// or a position to fall back on:
///
/// ```swift
/// .systemAlerts(.allow(orTap: "Allow"))
/// .systemAlerts(.deny(orTapButtonAt: 0))
/// ```
public struct SystemAlertAnswer: Sendable, Equatable {
    /// The button that gives this answer.
    let button: SystemAlertButton

    /// Give the app what it asked for.
    ///
    /// This is for alerts that say which of their buttons allows. See ``SystemAlert``
    /// for the ones that do. No alert does before iOS 27.
    public static let allow = Self(button: .allow)

    /// Refuse what the app asked for.
    ///
    /// This is for alerts that say which of their buttons refuses. See ``SystemAlert``
    /// for the ones that do. No alert does before iOS 27.
    public static let deny = Self(button: .deny)

    /// Tap the button with a label, such as "Allow While Using App".
    ///
    /// This is for any alert that has a button with this label.
    public static func button(_ label: String) -> Self {
        Self(button: .label(label))
    }

    /// Give the app what it asked for, and tap the button with a label in an alert
    /// that does not say which of its buttons allows.
    public static func allow(orTap label: String) -> Self {
        Self(button: .either(.allow, or: .label(label)))
    }

    /// Give the app what it asked for, and tap the button at a position in an alert
    /// that does not say which of its buttons allows. The position counts from 0.
    public static func allow(orTapButtonAt index: Int) -> Self {
        Self(button: .either(.allow, or: .index(index)))
    }

    /// Refuse what the app asked for, and tap the button with a label in an alert
    /// that does not say which of its buttons refuses.
    public static func deny(orTap label: String) -> Self {
        Self(button: .either(.deny, or: .label(label)))
    }

    /// Refuse what the app asked for, and tap the button at a position in an alert
    /// that does not say which of its buttons refuses. The position counts from 0.
    public static func deny(orTapButtonAt index: Int) -> Self {
        Self(button: .either(.deny, or: .index(index)))
    }
}

/// An answer, and the alerts it is for.
struct SystemAlertRule: Equatable, Sendable {
    var answer: SystemAlertAnswer

    /// The names the system gives the permissions this rule is for, such as
    /// "kTCCServiceMicrophone". Empty if the rule is for every alert.
    var services: [String] = []

    /// Whether the rule is for an alert with an identifier such as "kTCCServiceMicrophone-alert".
    ///
    /// On a system that does not mark its alerts, no alert says which permission it
    /// asks for. A rule for named permissions is for no alert there, because it could
    /// not leave the alerts of other permissions alone.
    func isFor(alertWithIdentifier identifier: String, marked: Bool) -> Bool {
        services.isEmpty || (marked && services.contains { identifier.hasPrefix("\($0)-") })
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
    ///
    /// - Parameters:
    ///   - identifier: The identifier of the alert.
    ///   - buttons: The alert's buttons, in order.
    ///   - marked: Whether the system marks its alerts and their buttons with identifiers.
    func positionOfButton(
        inAlertWithIdentifier identifier: String,
        buttons: [SystemAlertButtonInfo],
        marked: Bool = SystemAlertChoice.systemMarksAlerts
    ) -> Int? {
        for rule in rules.reversed() where rule.isFor(alertWithIdentifier: identifier, marked: marked) {
            let choice = SystemAlertChoice.position(
                of: rule.answer.button,
                inAlertTitled: "",
                withButtons: buttons,
                marked: marked
            )
            if case .success(let position) = choice {
                return position
            }
        }
        return nil
    }
}
