import AppKit

let logFile: FileHandle? = {
    let path = "/tmp/winkeys_debug.log"
    FileManager.default.createFile(atPath: path, contents: nil)
    return FileHandle(forWritingAtPath: path)
}()

func debugLog(_ msg: String) {
    let line = "\(Date()): \(msg)\n"
    logFile?.seekToEndOfFile()
    logFile?.write(line.data(using: .utf8)!)
    NSLog("WinKeys: \(msg)")
}

public final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    private var accessibilityTimer: Timer?

    public override init() {
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        debugLog("앱 시작")

        // 메뉴바 먼저 표시
        statusBarController = StatusBarController()
        debugLog("메뉴바 생성 완료")

        // 접근성 권한 확인
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        debugLog("접근성 권한: \(trusted)")

        if trusted {
            startEventTap()
        } else {
            debugLog("권한 대기 시작...")
            accessibilityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                let granted = AXIsProcessTrusted()
                if granted {
                    debugLog("권한 허용됨!")
                    self?.accessibilityTimer?.invalidate()
                    self?.accessibilityTimer = nil
                    self?.startEventTap()
                }
            }
        }
    }

    private func startEventTap() {
        debugLog("이벤트 탭 시작 시도...")
        let result = EventTapManager.shared.start()
        debugLog("이벤트 탭 시작 결과: \(result)")

        if !result {
            showAlert(
                title: L("app.error.title"),
                message: L("app.error.message")
            )
            return
        }

        debugLog("\(Preferences.shared.isWindowsMode ? "Windows" : "Mac") 모드로 시작됨")
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    public func applicationWillTerminate(_ notification: Notification) {
        accessibilityTimer?.invalidate()
        EventTapManager.shared.stop()
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: L("alert.confirm"))
        alert.runModal()
    }
}
