import XCTest

extension XCUIElement {
    /// Returns the element of a kind inside this one that has a label.
    ///
    /// Use this for an element that the app cannot give an identifier: one in a web
    /// view, on a screen that another library shows, or in an interface that the
    /// system provides. For the app's own views an identifier is better, because a
    /// label changes with the wording and the language of the app.
    ///
    /// The result is a ``UITestElement``, whose actions wait for the element to be ready:
    ///
    /// ```swift
    /// try app.element(ElementKinds.Link.self, labeled: "Terms").tap()
    /// ```
    ///
    /// The most common kinds have a shorter form, such as `app.button("Continue")`.
    ///
    /// The label has to be the whole of the element's label, in the same case. The
    /// element's identifier, title, value and placeholder are not looked at, as they
    /// are by `app.links["Terms"]`.
    ///
    /// Use it on the app to look everywhere, or on another element to look only
    /// inside it. If several elements of the kind have the label, an action on the
    /// result ends the test and says how many there were. Look inside the element that
    /// holds the one you mean.
    ///
    /// - Parameters:
    ///   - kind: The kind of element to look for, such as `ElementKinds.Link.self`.
    ///     `ElementKinds.AnyElement.self` matches an element of any kind.
    ///   - label: The label of the element, as it is shown.
    @MainActor
    public func element<Kind: ElementKind>(_ kind: Kind.Type, labeled label: String) -> UITestElement<Kind> {
        UITestElement(labeled: label, in: self, app: self as? XCUIApplication)
    }

    /// Returns the button inside this element that has a label.
    ///
    /// ```swift
    /// try app.button("Continue").tap()
    /// ```
    ///
    /// See ``element(_:labeled:)`` for how the label is matched.
    ///
    /// - Parameter label: The label of the button, as it is shown.
    @MainActor
    public func button(_ label: String) -> UITestElement<ElementKinds.Button> {
        element(ElementKinds.Button.self, labeled: label)
    }

    /// Returns the text inside this element that has a label, which for text is what it says.
    ///
    /// ```swift
    /// #expect(app.staticText("Welcome back").exists)
    /// ```
    ///
    /// See ``element(_:labeled:)`` for how the label is matched.
    ///
    /// - Parameter label: The text, as it is shown.
    @MainActor
    public func staticText(_ label: String) -> UITestElement<ElementKinds.StaticText> {
        element(ElementKinds.StaticText.self, labeled: label)
    }

    /// Returns the link inside this element that has a label.
    ///
    /// ```swift
    /// try app.link("Terms").tap()
    /// ```
    ///
    /// See ``element(_:labeled:)`` for how the label is matched.
    ///
    /// - Parameter label: The label of the link, as it is shown.
    @MainActor
    public func link(_ label: String) -> UITestElement<ElementKinds.Link> {
        element(ElementKinds.Link.self, labeled: label)
    }

    /// Returns the single-line text field inside this element that has a label.
    ///
    /// ```swift
    /// try app.textField("Email").enter("ada@example.com")
    /// ```
    ///
    /// See ``element(_:labeled:)`` for how the label is matched.
    ///
    /// - Parameter label: The label of the field. This is not the text it holds.
    @MainActor
    public func textField(_ label: String) -> UITestElement<ElementKinds.TextField> {
        element(ElementKinds.TextField.self, labeled: label)
    }

    /// Returns the field for hidden text, such as a password, inside this element that has a label.
    ///
    /// ```swift
    /// try app.secureTextField("Password").enter("correct horse")
    /// ```
    ///
    /// See ``element(_:labeled:)`` for how the label is matched.
    ///
    /// - Parameter label: The label of the field. This is not the text it holds.
    @MainActor
    public func secureTextField(_ label: String) -> UITestElement<ElementKinds.SecureTextField> {
        element(ElementKinds.SecureTextField.self, labeled: label)
    }

    /// Returns the switch inside this element that has a label.
    ///
    /// ```swift
    /// try app.switch("Notifications").setOn(true)
    /// ```
    ///
    /// See ``element(_:labeled:)`` for how the label is matched.
    ///
    /// - Parameter label: The label of the switch, as it is shown.
    @MainActor
    public func `switch`(_ label: String) -> UITestElement<ElementKinds.Switch> {
        element(ElementKinds.Switch.self, labeled: label)
    }

    /// Returns the cell of a table or collection view inside this element that has a label.
    ///
    /// ```swift
    /// try app.cell("Wi-Fi").tap()
    /// ```
    ///
    /// See ``element(_:labeled:)`` for how the label is matched.
    ///
    /// - Parameter label: The label of the cell.
    @MainActor
    public func cell(_ label: String) -> UITestElement<ElementKinds.Cell> {
        element(ElementKinds.Cell.self, labeled: label)
    }

    /// Returns the image inside this element that has a label.
    ///
    /// ```swift
    /// #expect(app.image("Company logo").exists)
    /// ```
    ///
    /// See ``element(_:labeled:)`` for how the label is matched.
    ///
    /// - Parameter label: The label of the image.
    @MainActor
    public func image(_ label: String) -> UITestElement<ElementKinds.Image> {
        element(ElementKinds.Image.self, labeled: label)
    }
}

extension UITestElement {
    /// Returns the element of a kind inside this one that has a label.
    ///
    /// Use this for an element that the app cannot give an identifier, and to tell
    /// apart elements that have the same label:
    ///
    /// ```swift
    /// try app[BasketID.row(3)].element(ElementKinds.Link.self, labeled: "Details").tap()
    /// ```
    ///
    /// The most common kinds have a shorter form, such as ``button(_:)``.
    ///
    /// The label has to be the whole of the element's label, in the same case. The
    /// element's identifier, title, value and placeholder are not looked at.
    ///
    /// If several elements of the kind inside this one have the label, an action on
    /// the result ends the test and says how many there were.
    ///
    /// - Parameters:
    ///   - kind: The kind of element to look for, such as `ElementKinds.Link.self`.
    ///     `ElementKinds.AnyElement.self` matches an element of any kind.
    ///   - label: The label of the element, as it is shown.
    public func element<Child: ElementKind>(_ kind: Child.Type, labeled label: String) -> UITestElement<Child> {
        UITestElement<Child>(labeled: label, in: element, app: app)
    }

    /// Returns the button inside this element that has a label.
    ///
    /// ```swift
    /// try app[BasketID.row(3)].button("Remove").tap()
    /// ```
    ///
    /// See ``element(_:labeled:)`` for how the label is matched.
    ///
    /// - Parameter label: The label of the button, as it is shown.
    public func button(_ label: String) -> UITestElement<ElementKinds.Button> {
        element(ElementKinds.Button.self, labeled: label)
    }

    /// Returns the text inside this element that has a label, which for text is what it says.
    ///
    /// ```swift
    /// #expect(app[BasketID.row(3)].staticText("Out of stock").exists)
    /// ```
    ///
    /// See ``element(_:labeled:)`` for how the label is matched.
    ///
    /// - Parameter label: The text, as it is shown.
    public func staticText(_ label: String) -> UITestElement<ElementKinds.StaticText> {
        element(ElementKinds.StaticText.self, labeled: label)
    }

    /// Returns the link inside this element that has a label.
    ///
    /// See ``element(_:labeled:)`` for how the label is matched.
    ///
    /// - Parameter label: The label of the link, as it is shown.
    public func link(_ label: String) -> UITestElement<ElementKinds.Link> {
        element(ElementKinds.Link.self, labeled: label)
    }

    /// Returns the single-line text field inside this element that has a label.
    ///
    /// See ``element(_:labeled:)`` for how the label is matched.
    ///
    /// - Parameter label: The label of the field. This is not the text it holds.
    public func textField(_ label: String) -> UITestElement<ElementKinds.TextField> {
        element(ElementKinds.TextField.self, labeled: label)
    }

    /// Returns the field for hidden text, such as a password, inside this element that has a label.
    ///
    /// See ``element(_:labeled:)`` for how the label is matched.
    ///
    /// - Parameter label: The label of the field. This is not the text it holds.
    public func secureTextField(_ label: String) -> UITestElement<ElementKinds.SecureTextField> {
        element(ElementKinds.SecureTextField.self, labeled: label)
    }

    /// Returns the switch inside this element that has a label.
    ///
    /// See ``element(_:labeled:)`` for how the label is matched.
    ///
    /// - Parameter label: The label of the switch, as it is shown.
    public func `switch`(_ label: String) -> UITestElement<ElementKinds.Switch> {
        element(ElementKinds.Switch.self, labeled: label)
    }

    /// Returns the cell of a table or collection view inside this element that has a label.
    ///
    /// See ``element(_:labeled:)`` for how the label is matched.
    ///
    /// - Parameter label: The label of the cell.
    public func cell(_ label: String) -> UITestElement<ElementKinds.Cell> {
        element(ElementKinds.Cell.self, labeled: label)
    }

    /// Returns the image inside this element that has a label.
    ///
    /// See ``element(_:labeled:)`` for how the label is matched.
    ///
    /// - Parameter label: The label of the image.
    public func image(_ label: String) -> UITestElement<ElementKinds.Image> {
        element(ElementKinds.Image.self, labeled: label)
    }
}

/// What an element that was looked up by its label was looked up with.
struct LabelMatch {
    /// The label that was looked for.
    let label: String

    /// Every element of the kind that has the label, in what the element was looked up in.
    let matches: XCUIElementQuery
}

extension UITestElement {
    /// Creates the element of this kind that has a label, inside another element.
    ///
    /// - Parameters:
    ///   - label: The whole of the element's label.
    ///   - scope: The element to look inside.
    ///   - app: The app that `scope` is, or was looked up in, if that is known.
    init(labeled label: String, in scope: XCUIElement, app: XCUIApplication?) {
        // The string subscript of a query also matches identifiers, titles, values
        // and placeholders, so the label is matched with a predicate.
        let hasLabel = NSPredicate(format: "label == %@", label)
        let matches = scope.descendants(matching: XCUIElement.ElementType(Kind.elementType)).matching(hasLabel)
        self.init(
            // Not the first match: with several, nothing says which one is meant.
            element: matches.element,
            accessibilityIdentifier: "",
            elementOfAnyKind: Kind.elementType == .any
                ? nil : scope.descendants(matching: .any).matching(hasLabel).firstMatch,
            scope: scope,
            app: app,
            labelMatch: LabelMatch(label: label, matches: matches)
        )
    }

    /// How the element was found, which is how the description of a failure refers to it.
    var reference: ElementReference {
        guard let labelMatch else { return .identifier(accessibilityIdentifier) }
        return .label(labelMatch.label, kind: Kind.elementType == .any ? "element" : Kind.elementType.rawValue)
    }
}
