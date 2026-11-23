import Foundation

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
    ///
    /// The identifier is `nil` for an alert that nothing is known about. A rule is for
    /// such an alert, because it could be one of those the rule names.
    func isFor(alertWithIdentifier identifier: String?) -> Bool {
        guard let identifier else { return true }
        return services.isEmpty || services.contains { identifier.hasPrefix("\($0)-") }
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
    ///   - identifier: The identifier of the alert, or `nil` if what the alert asks
    ///     for is not known.
    ///   - buttons: The alert's buttons, in order.
    ///   - marked: Whether the system marks its alerts and their buttons with identifiers.
    func positionOfButton(
        inAlertWithIdentifier identifier: String?,
        buttons: [SystemAlertButtonInfo],
        marked: Bool = SystemAlertChoice.systemMarksAlerts
    ) -> Int? {
        for rule in rules.reversed() where rule.isFor(alertWithIdentifier: identifier) {
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

/// Tells what an alert asks for from its title, on a system that does not mark its alerts.
///
/// Before iOS 27 an alert has no identifier. Its title is one that the system keeps
/// for each permission, in each language, with a place for the name of the app, such
/// as "“%@” Would Like to Access the Microphone".
enum SystemAlertTitles {
    /// Where the system keeps its titles.
    static let systemBundlePath = "/System/Library/PrivateFrameworks/TCC.framework"

    /// Returns the name the system has for the title of a permission's alert.
    static func key(forService service: String) -> String {
        "REQUEST_ACCESS_SERVICE_\(service)"
    }

    /// Whether a title is the system's title for a permission, with the name of some app in it.
    static func matches(_ title: String, format: String) -> Bool {
        let parts = format.components(separatedBy: "%@")
        guard parts.count == 2, !(parts[0].isEmpty && parts[1].isEmpty) else { return false }
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let start = parts[0]
        let end = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
        return title.count > start.count + end.count && title.hasPrefix(start) && title.hasSuffix(end)
    }

    /// Returns the identifier that an alert would have on a system that marks its
    /// alerts, such as "kTCCServiceMicrophone-alert".
    ///
    /// It is empty for an alert that is for none of the permissions, and `nil` if the
    /// title of one of them is not known, so that the alert could be for that one.
    ///
    /// - Parameters:
    ///   - title: The title of the alert.
    ///   - services: The names of the permissions that the test's rules are for.
    ///   - format: Returns the system's title for a permission, or `nil` if it has none.
    static func identifier(
        forAlertTitled title: String,
        services: [String],
        format: (String) -> String?
    ) -> String? {
        var everyTitleIsKnown = true
        for service in services {
            guard let format = format(service) else {
                everyTitleIsKnown = false
                continue
            }
            if matches(title, format: format) {
                return "\(service)-alert"
            }
        }
        return everyTitleIsKnown ? "" : nil
    }

    /// Returns the title that the system on this device has for a permission's alert,
    /// in the language of the device.
    static func systemFormat(forService service: String) -> String? {
        // In a simulator the files of the system are under this folder of the Mac.
        let root = ProcessInfo.processInfo.environment["IPHONE_SIMULATOR_ROOT"] ?? ""
        guard let bundle = Bundle(path: root + systemBundlePath) else { return nil }
        let key = key(forService: service)
        let title = bundle.localizedString(forKey: key, value: key, table: nil)
        return title == key ? nil : title
    }
}
