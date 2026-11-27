import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

#if !os(macOS)
// Compatibility for UIKit (iOS & iPadOS)
public typealias NSColor = UIColor

public extension UIColor {
    static var controlBackgroundColor: UIColor { .secondarySystemBackground }
    static var textBackgroundColor: UIColor { .systemBackground }
    static var windowBackgroundColor: UIColor { .systemBackground }
}

public extension Color {
    init(_ uiColor: UIColor) {
        self.init(uiColor: uiColor)
    }
}
#endif

/// Cross-platform clipboard helper
public func copyToClipboard(_ text: String) {
    #if os(macOS)
    let pb = NSPasteboard.general
    pb.clearContents()
    pb.setString(text, forType: .string)
    #elseif os(iOS)
    UIPasteboard.general.string = text
    #endif
}

/// Cross-platform notification sound or haptic feedback
public func playAlertSound() {
    #if os(macOS)
    NSSound.beep()
    #elseif os(iOS)
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)
    #endif
}

public extension View {
    /// Responsive frame for sheets: fixed on macOS desktop, flexible on iOS/iPadOS
    @ViewBuilder
    func macSheetFrame(width: CGFloat, height: CGFloat? = nil) -> some View {
        #if os(macOS)
        if let height = height {
            self.frame(width: width, height: height)
        } else {
            self.frame(width: width)
        }
        #else
        self
        #endif
    }
}
