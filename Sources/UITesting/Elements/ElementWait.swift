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

    /// The type of an element that has the same identifier, or the same label, but is
    /// another kind, if there is one.
    var typeOfElementWithSameIdentifier: () -> String?

    /// How many elements the lookup matches, for a lookup that can match several, such
    /// as one by label. Read once the element exists, and when it never appeared.
    var matchCount: (() -> Int)? = nil
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
        failure(
            intent: intent,
            element: .identifier(identifier),
            kind: kind,
            requirement: requirement,
            timeout: timeout,
            polling: polling,
            probe: probe
        )
    }

    /// Waits until the element meets the requirement or the timeout has passed.
    ///
    /// An element that has to be there, and that the lookup matches more than once, is
    /// a failure as soon as it is seen, because nothing says which of them is meant.
    ///
    /// - Parameters:
    ///   - intent: What the wait is for, completing the sentence "Could not …", such as "tap".
    ///   - element: How the element was found.
    ///   - kind: The kind of element that was looked for, such as "button".
    /// - Returns: `nil` if the requirement was met, and a description of the failure if not.
    static func failure(
        intent: String,
        element: ElementReference,
        kind: String,
        requirement: ElementRequirement,
        timeout: Duration,
        polling: ExpectationPolling = ExpectationPolling(),
        probe: ElementProbe
    ) -> String? {
        let summary = "Could not \(intent) \(element.name)"
        var matches = 1
        let outcome = polling.wait(timeout: timeout) {
            switch requirement {
            case .absent:
                return !probe.exists()
            case .exists, .enabled:
                guard probe.exists() else { return false }
                // XCTest fails a read of an element that is matched more than once, so
                // nothing else is read from one.
                if let count = probe.matchCount?(), count > 1 {
                    matches = count
                    return true
                }
                return requirement == .exists || probe.isEnabled()
            }
        }
        guard matches == 1 else { return "\(summary): \(element.reasonForMatching(matches))" }
        guard outcome != .met else { return nil }

        let time = ExpectationFailure.describe(timeout)
        switch requirement {
        case .absent:
            return "\(summary): the \(kind) was still there after \(time)"
        case .enabled where probe.exists():
            return "\(summary): the \(kind) was still disabled after \(time)"
        case .exists, .enabled:
            if let count = probe.matchCount?(), count > 1 {
                return "\(summary): \(element.reasonForMatching(count))"
            }
            var message = "\(summary): no \(kind) with this \(element.attribute) appeared within \(time)"
            if let otherType = probe.typeOfElementWithSameIdentifier() {
                message += "\n" + element.hint(forElementOfType: otherType)
            }
            return message
        }
    }
}
