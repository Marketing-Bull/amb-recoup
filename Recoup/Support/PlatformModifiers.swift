import SwiftUI

#if os(iOS)
extension View {
    /// Decimal pad on iOS; no-op on macOS.
    func decimalKeyboard() -> some View {
        keyboardType(.decimalPad)
    }

    /// Inline navigation bar title on iOS; no-op on macOS.
    func inlineNavigationTitle() -> some View {
        navigationBarTitleDisplayMode(.inline)
    }
}
#else
extension View {
    func decimalKeyboard() -> some View { self }
    func inlineNavigationTitle() -> some View { self }
}
#endif
