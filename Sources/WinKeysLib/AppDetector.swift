import AppKit

final class AppDetector {
    static let shared = AppDetector()

    private let terminalBundleIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.mitchellh.ghostty",
        "net.kovidgoyal.kitty",
        "io.alacritty",
        "co.zeit.hyper",
        "dev.warp.Warp-Stable",
        "dev.warp.Warp",
    ]

    private let finderBundleID = "com.apple.finder"

    var currentAppBundleID: String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    var isTerminalApp: Bool {
        guard let bundleID = currentAppBundleID else { return false }
        return terminalBundleIDs.contains(bundleID)
    }

    var isFinderApp: Bool {
        currentAppBundleID == finderBundleID
    }
}
