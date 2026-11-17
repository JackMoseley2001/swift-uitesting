import Foundation

/// Links that the demo app opens, through its `uitestingdemo` URL scheme.
enum DemoLink {
    /// A link to an order, such as `uitestingdemo://orders/42`.
    static func order(_ number: Int) -> URL {
        URL(string: "uitestingdemo://orders/\(number)")!
    }
}
