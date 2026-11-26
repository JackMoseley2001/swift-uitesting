import XCTest

/// The elements that an accessibility audit can be told to ignore issues of.
///
/// ``ElementID`` and ``ElementIDFamily`` conform, so the keys of the `ignoring`
/// argument of ``UITestContext/runAccessibilityAudit(for:ignoring:filePath:line:)``
/// can be identifiers of different kinds, and families:
///
/// ```swift
/// try context.runAccessibilityAudit(
///     ignoring: [
///         LoginID.signInButton: .contrast,
///         InboxID.row: [.dynamicType, .textClipped]
///     ]
/// )
/// ```
///
/// You do not conform your own types to this protocol.
public protocol AccessibilityAuditScope {
    /// How to tell whether an element with an identifier is one of these elements.
    var accessibilityAuditMatch: AccessibilityAuditMatch { get }
}

/// How an accessibility audit tells whether an element is one it was told to ignore
/// issues of.
public struct AccessibilityAuditMatch: Hashable, Sendable {
    /// The identifier that the element has to have, or to start with.
    let identifier: String

    /// Whether an element whose identifier starts with ``identifier`` also matches.
    let isPrefix: Bool

    /// Whether an element with an identifier is one of the elements this stands for.
    func matches(_ elementIdentifier: String) -> Bool {
        isPrefix ? elementIdentifier.hasPrefix(identifier) : elementIdentifier == identifier
    }
}

extension ElementID: AccessibilityAuditScope {
    /// Matches the element with this identifier.
    public var accessibilityAuditMatch: AccessibilityAuditMatch {
        AccessibilityAuditMatch(identifier: accessibilityIdentifier, isPrefix: false)
    }
}

extension ElementIDFamily: AccessibilityAuditScope {
    /// Matches every element of the family.
    public var accessibilityAuditMatch: AccessibilityAuditMatch {
        AccessibilityAuditMatch(identifier: accessibilityIdentifierPrefix, isPrefix: true)
    }
}

/// The issues that an accessibility audit does not report, by the element they are about.
///
/// You write one as a dictionary, from an identifier or a family of identifiers to the
/// types of issue to ignore for it:
///
/// ```swift
/// try context.runAccessibilityAudit(
///     ignoring: [
///         LoginID.signInButton: .contrast,
///         LoginID.terms: [.dynamicType, .textClipped],
///         InboxID.row: .all
///     ]
/// )
/// ```
///
/// An element is matched by its own accessibility identifier, so ignoring an element
/// does not ignore the issues of the elements inside it.
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *)
public struct AccessibilityAuditExclusions: ExpressibleByDictionaryLiteral, Sendable {
    /// The types of issue to ignore, for each of the elements that were named.
    let rules: [(match: AccessibilityAuditMatch, types: XCUIAccessibilityAuditType)]

    /// Creates the exclusions from pairs of elements and the types of issue to ignore
    /// for them.
    ///
    /// - Parameter elements: An identifier or a family, and the types of issue that
    ///   are not reported for it.
    public init(dictionaryLiteral elements: (any AccessibilityAuditScope, XCUIAccessibilityAuditType)...) {
        rules = elements.map { (match: $0.accessibilityAuditMatch, types: $1) }
    }

    /// Whether an issue of one type, about the element with an identifier, is ignored.
    ///
    /// An issue about an element that has no identifier is never ignored, because
    /// nothing here can name the element.
    func ignores(_ type: XCUIAccessibilityAuditType, forElementIdentifiedBy identifier: String?) -> Bool {
        guard let identifier, !identifier.isEmpty else { return false }
        return rules.contains { $0.match.matches(identifier) && !$0.types.isDisjoint(with: type) }
    }
}

/// The parts of an accessibility audit that do not need a running app.
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *)
enum AccessibilityAudit {
    /// An issue that an audit found, with what is known about its element.
    struct Issue: Equatable {
        /// The type of the audit that found the issue.
        let type: XCUIAccessibilityAuditType

        /// What is wrong, in a few words, such as "Contrast failed".
        let summary: String

        /// A longer account of what is wrong.
        let detail: String

        /// The accessibility identifier of the element, if the issue is about an
        /// element and it has one.
        let identifier: String?

        /// How XCTest describes the element, if the issue is about one.
        let element: String?
    }

    /// The names of the types of audit, as they are written in code. The types that
    /// only some platforms have are found by their raw values, which every platform
    /// agrees on.
    private static let typeNames: [(rawValue: UInt64, name: String)] = [
        (1 << 0, "contrast"),
        (1 << 1, "elementDetection"),
        (1 << 2, "hitRegion"),
        (1 << 3, "sufficientElementDescription"),
        (1 << 16, "dynamicType"),
        (1 << 17, "textClipped"),
        (1 << 18, "trait"),
        (1 << 32, "action"),
        (1 << 33, "parentChild")
    ]

    /// Returns the issues to report, which are those that the exclusions do not ignore.
    static func reported(_ issues: [Issue], ignoring exclusions: AccessibilityAuditExclusions) -> [Issue] {
        issues.filter { !exclusions.ignores($0.type, forElementIdentifiedBy: $0.identifier) }
    }

    /// Describes an issue, saying which element it is about and how to ignore it.
    static func message(for issue: Issue) -> String {
        var summary = "Accessibility audit: \(issue.summary)"
        if let identifier = issue.identifier, !identifier.isEmpty {
            summary += " on \(identifier)"
        } else if let element = issue.element, !element.isEmpty {
            summary += " on \(element)"
        }
        var lines = [summary]
        if !issue.detail.isEmpty, issue.detail != issue.summary {
            lines.append(issue.detail)
        }
        if let name = name(of: issue.type) {
            lines.append("The type of this issue is .\(name).")
        }
        return lines.joined(separator: "\n")
    }

    /// The name of a type of audit as it is written in code, such as "contrast", or
    /// `nil` for a type that this version of the library does not know.
    static func name(of type: XCUIAccessibilityAuditType) -> String? {
        typeNames.first { $0.rawValue == type.rawValue }?.name
    }
}
