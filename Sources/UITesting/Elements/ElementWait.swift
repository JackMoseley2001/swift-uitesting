/// What an action needs of an element before it can go ahead.
enum ElementRequirement {
    /// The element exists.
    case exists

    /// The element exists and is enabled.
    case enabled

    /// The element does not exist.
    case absent
}

/// What is read from an element while waiting for it.
struct ElementProbe {
    /// Whether the element exists.
    var exists: () -> Bool

    /// Whether the element is enabled. Only read when the element exists.
    var isEnabled: () -> Bool

    /// The type of an element that has the same identifier but is another kind, if there is one.
    var typeOfElementWithSameIdentifier: () -> String?
}

/// Waits for an element to meet a requirement, and describes what went wrong if it does not.
enum ElementWait {
    /// Waits until the element meets the requirement or the timeout has passed.
    ///
    /// - Parameters:
    ///   - intent: What the wait is for, completing the sentence "Could not …", such as "tap".
    ///   - identifier: The accessibility identifier of the element.
    ///   - kind: The kind of element that was looked for, such as "button".
    /// - Returns: `nil` if the requirement was met, and a description of the failure if not.
    static func failure(
        intent: String,
        identifier: String,
        kind: String,
        requirement: ElementRequirement,
        timeout: Duration,
        polling: ExpectationPolling = ExpectationPolling(),
        probe: ElementProbe
    ) -> String? {
        let outcome = polling.wait(timeout: timeout) {
            switch requirement {
            case .exists: probe.exists()
            case .enabled: probe.exists() && probe.isEnabled()
            case .absent: !probe.exists()
            }
        }
        guard outcome != .met else { return nil }

        let time = ExpectationFailure.describe(timeout)
        let summary = "Could not \(intent) \(identifier)"
        switch requirement {
        case .absent:
            return "\(summary): the \(kind) was still there after \(time)"
        case .enabled where probe.exists():
            return "\(summary): the \(kind) was still disabled after \(time)"
        case .exists, .enabled:
            var message = "\(summary): no \(kind) with this identifier appeared within \(time)"
            if let otherType = probe.typeOfElementWithSameIdentifier() {
                message += "\nAn element of type \(otherType) has this identifier. "
                    + "Is the identifier declared as the wrong kind?"
            }
            return message
        }
    }
}
