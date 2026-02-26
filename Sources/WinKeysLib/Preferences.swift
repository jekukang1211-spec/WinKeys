import Foundation
import CoreGraphics
import Carbon

final class Preferences {
    static let shared = Preferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let isWindowsMode = "isWindowsMode"
        static let languageKeyCode = "languageKeyCode"
        static let languageKeyConfigured = "languageKeyConfigured"
        static let launchAtLogin = "launchAtLogin"
    }

    var isWindowsMode: Bool {
        get {
            if defaults.object(forKey: Keys.isWindowsMode) == nil {
                return true // Default: Windows mode
            }
            return defaults.bool(forKey: Keys.isWindowsMode)
        }
        set { defaults.set(newValue, forKey: Keys.isWindowsMode) }
    }

    /// 기본값: Right Alt (0x3D = rightOption)
    var languageKeyCode: CGKeyCode? {
        get {
            if defaults.bool(forKey: Keys.languageKeyConfigured) {
                return CGKeyCode(defaults.integer(forKey: Keys.languageKeyCode))
            }
            // 기본값: Right Alt
            return CGKeyCode(kVK_RightOption)
        }
        set {
            if let code = newValue {
                defaults.set(Int(code), forKey: Keys.languageKeyCode)
                defaults.set(true, forKey: Keys.languageKeyConfigured)
            } else {
                defaults.removeObject(forKey: Keys.languageKeyCode)
                defaults.set(false, forKey: Keys.languageKeyConfigured)
            }
        }
    }

    var isLanguageKeyConfigured: Bool {
        defaults.bool(forKey: Keys.languageKeyConfigured)
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set { defaults.set(newValue, forKey: Keys.launchAtLogin) }
    }
}
