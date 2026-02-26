import ServiceManagement

final class LoginItemManager {
    static let shared = LoginItemManager()

    var isEnabled: Bool {
        get { Preferences.shared.launchAtLogin }
        set {
            Preferences.shared.launchAtLogin = newValue
            updateLoginItem(enabled: newValue)
        }
    }

    func updateLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("WinKeys: Failed to update login item: \(error)")
            }
        }
    }
}
