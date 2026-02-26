import AppKit
import CoreGraphics

final class LanguageKeyRecorder {
    private var window: NSWindow?
    private var eventMonitor: Any?
    private var globalMonitor: Any?
    var onComplete: (() -> Void)?

    func showRecorderPanel() {
        // 이벤트 탭 일시 중지 (키 입력이 여기로 와야 하므로)
        EventTapManager.shared.stop()

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 180),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = L("lang.windowTitle")
        panel.level = .floating
        panel.center()

        let contentView = NSView(frame: panel.contentView!.bounds)

        let label = NSTextField(wrappingLabelWithString: L("lang.prompt"))
        label.frame = NSRect(x: 30, y: 90, width: 340, height: 60)
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 15)
        contentView.addSubview(label)

        let sublabel = NSTextField(wrappingLabelWithString: L("lang.waiting"))
        sublabel.frame = NSRect(x: 30, y: 50, width: 340, height: 30)
        sublabel.alignment = .center
        sublabel.font = NSFont.systemFont(ofSize: 12)
        sublabel.textColor = .secondaryLabelColor
        contentView.addSubview(sublabel)

        let skipButton = NSButton(title: L("lang.skip"), target: nil, action: nil)
        skipButton.frame = NSRect(x: 150, y: 10, width: 100, height: 32)
        skipButton.target = self
        skipButton.action = #selector(skipPressed)
        contentView.addSubview(skipButton)

        panel.contentView = contentView
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        self.window = panel

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        let modifierKeys: Set<CGKeyCode> = [
            KeyCode.option, KeyCode.rightOption,
            KeyCode.control, KeyCode.rightControl,
            KeyCode.shift, KeyCode.rightShift,
            KeyCode.command, KeyCode.rightCommand,
            KeyCode.capsLock,
        ]

        // 로컬 모니터 (앱이 포커스일 때)
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self = self else { return event }
            let keyCode = CGKeyCode(event.keyCode)
            if event.type == .flagsChanged {
                guard modifierKeys.contains(keyCode) else { return event }
            }
            Preferences.shared.languageKeyCode = keyCode
            debugLog("언어 전환 키 설정됨: keyCode=\(keyCode)")
            self.cleanup()
            return nil
        }

        // 글로벌 모니터 (다른 앱이 포커스일 때도 감지)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self = self else { return }
            let keyCode = CGKeyCode(event.keyCode)
            if event.type == .flagsChanged {
                guard modifierKeys.contains(keyCode) else { return }
            }
            Preferences.shared.languageKeyCode = keyCode
            debugLog("언어 전환 키 설정됨 (글로벌): keyCode=\(keyCode)")
            self.cleanup()
        }
    }

    @objc private func skipPressed() {
        cleanup()
    }

    private func cleanup() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        window?.close()
        window = nil
        NSApp.setActivationPolicy(.accessory)

        // 이벤트 탭 다시 시작
        _ = EventTapManager.shared.start()
        debugLog("이벤트 탭 재시작됨")

        onComplete?()
    }

    func showChangeKeyPanel() {
        showRecorderPanel()
    }
}
