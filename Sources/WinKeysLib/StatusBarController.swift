import AppKit

final class StatusBarController {
    private var statusItem: NSStatusItem!
    private let mappingEditor = MappingEditorWindow()

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon()
        buildMenu()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(modeDidChange),
            name: .modeChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageDidChange),
            name: .languageChanged,
            object: nil
        )
    }

    private func updateIcon() {
        let title = Preferences.shared.isWindowsMode ? "W" : "M"
        if let button = statusItem.button {
            button.title = title
            button.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        }
    }

    private func buildMenu() {
        let menu = NSMenu()

        let modeItem = NSMenuItem(
            title: Preferences.shared.isWindowsMode ? L("menu.currentMode.windows") : L("menu.currentMode.mac"),
            action: nil,
            keyEquivalent: ""
        )
        modeItem.isEnabled = false
        menu.addItem(modeItem)

        menu.addItem(NSMenuItem.separator())

        let winModeItem = NSMenuItem(
            title: L("menu.switchWindows"),
            action: #selector(switchToWindowsMode),
            keyEquivalent: ""
        )
        winModeItem.target = self
        winModeItem.isEnabled = !Preferences.shared.isWindowsMode
        menu.addItem(winModeItem)

        let macModeItem = NSMenuItem(
            title: L("menu.switchMac"),
            action: #selector(switchToMacMode),
            keyEquivalent: ""
        )
        macModeItem.target = self
        macModeItem.isEnabled = Preferences.shared.isWindowsMode
        menu.addItem(macModeItem)

        menu.addItem(NSMenuItem.separator())

        let mappingItem = NSMenuItem(
            title: L("menu.settings"),
            action: #selector(openMappingEditor),
            keyEquivalent: ""
        )
        mappingItem.target = self
        menu.addItem(mappingItem)

        menu.addItem(NSMenuItem.separator())

        // Language submenu
        let langMenu = NSMenu()
        let currentLang = Preferences.shared.appLanguage
        for lang in availableLanguages {
            let item = NSMenuItem(
                title: lang.nativeName,
                action: #selector(changeLanguage(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = lang.code
            item.state = (lang.code == currentLang) ? .on : .off
            langMenu.addItem(item)
        }
        let langItem = NSMenuItem(
            title: L("menu.language"),
            action: nil,
            keyEquivalent: ""
        )
        langItem.submenu = langMenu
        menu.addItem(langItem)

        let loginItem = NSMenuItem(
            title: L("menu.launchAtLogin"),
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = LoginItemManager.shared.isEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: L("menu.quit"),
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func modeDidChange() {
        updateIcon()
        buildMenu()
    }

    @objc private func languageDidChange() {
        buildMenu()
    }

    @objc private func switchToWindowsMode() {
        Preferences.shared.isWindowsMode = true
        NotificationCenter.default.post(name: .modeChanged, object: nil)
    }

    @objc private func switchToMacMode() {
        Preferences.shared.isWindowsMode = false
        NotificationCenter.default.post(name: .modeChanged, object: nil)
    }

    @objc private func openMappingEditor() {
        mappingEditor.show()
    }

    @objc private func changeLanguage(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String else { return }
        Preferences.shared.appLanguage = code
        updateLanguageBundle()
        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }

    @objc private func toggleLaunchAtLogin() {
        LoginItemManager.shared.isEnabled.toggle()
        buildMenu()
    }

    @objc private func quitApp() {
        EventTapManager.shared.stop()
        NSApp.terminate(nil)
    }
}
