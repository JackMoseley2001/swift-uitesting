import SwiftUI

extension KeyboardDismissal {
    /// The SwiftUI mode for a scroll view.
    var mode: ScrollDismissesKeyboardMode {
        switch self {
        case .automatic: .automatic
        case .immediately: .immediately
        case .interactively: .interactively
        case .never: .never
        }
    }
}
