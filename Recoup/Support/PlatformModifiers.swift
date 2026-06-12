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

    /// Email keyboard with autocapitalization/correction off on iOS; no-op on macOS.
    func emailField() -> some View {
        keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
    }
}
#else
extension View {
    func decimalKeyboard() -> some View { self }
    func inlineNavigationTitle() -> some View { self }
    func emailField() -> some View { self }
}
#endif
