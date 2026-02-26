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
            title: Preferences.shared.isWindowsMode ? "현재 모드: Windows" : "현재 모드: Mac",
            action: nil,
            keyEquivalent: ""
        )
        modeItem.isEnabled = false
        menu.addItem(modeItem)

        menu.addItem(NSMenuItem.separator())

        let winModeItem = NSMenuItem(
            title: "Windows 모드로 전환",
            action: #selector(switchToWindowsMode),
            keyEquivalent: ""
        )
        winModeItem.target = self
        winModeItem.isEnabled = !Preferences.shared.isWindowsMode
        menu.addItem(winModeItem)

        let macModeItem = NSMenuItem(
            title: "Mac 모드로 전환",
            action: #selector(switchToMacMode),
            keyEquivalent: ""
        )
        macModeItem.target = self
        macModeItem.isEnabled = Preferences.shared.isWindowsMode
        menu.addItem(macModeItem)

        menu.addItem(NSMenuItem.separator())

        let mappingItem = NSMenuItem(
            title: "단축키 설정...",
            action: #selector(openMappingEditor),
            keyEquivalent: ""
        )
        mappingItem.target = self
        menu.addItem(mappingItem)

        menu.addItem(NSMenuItem.separator())

        let loginItem = NSMenuItem(
            title: "로그인 시 자동 실행",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = LoginItemManager.shared.isEnabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(
            title: "WinKeys 종료",
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

    @objc private func toggleLaunchAtLogin() {
        LoginItemManager.shared.isEnabled.toggle()
        buildMenu()
    }

    @objc private func quitApp() {
        EventTapManager.shared.stop()
        NSApp.terminate(nil)
    }
}
