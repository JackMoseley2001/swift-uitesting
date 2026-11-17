/// An item in the demo's list. The app shows these, and UI tests refer to them by `id`.
struct Fruit: Identifiable, Equatable, CustomStringConvertible {
    let id: Int
    let name: String

    /// The name on its own, which is how a UI test that takes a fruit as an argument refers to it.
    var description: String { name }

    static let apple = Fruit(id: 101, name: "Apple")
    static let pear = Fruit(id: 102, name: "Pear")
    static let cherry = Fruit(id: 103, name: "Cherry")

    static let all = [apple, pear, cherry]
}
