import AppKit
import Carbon

// 레코더 모드
private enum RecordingMode {
    case input       // Windows 입력 단축키 변경
    case macInput    // Mac 모드 입력 단축키 변경
    case languageKey // 언어 전환 키 변경 (단일 키, 수식키 가능)
}

// 매핑 편집 창: 모든 단축키 목록 + 편집 기능
final class MappingEditorWindow: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    private var window: NSWindow?
    private var tableView: NSTableView!
    private var editEnabled = false
    private var editToggleButton: NSButton!
    private var lockLabel: NSTextField!

    struct DisplayMapping {
        let category: String
        let description: String
        let inputShortcut: String
        let outputShortcut: String
        // 기본값 (매핑 ID 용)
        let inputKey: CGKeyCode
        let inputMods: ModMask
        let outputKey: CGKeyCode
        let outputFlags: CGEventFlags
        let scope: MappingScope
        let isHeader: Bool
        let isLanguageToggle: Bool  // 언어 전환 키 (출력 변경 불가)
    }

    private var displayMappings: [DisplayMapping] = []

    func show() {
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        buildDisplayMappings()

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        w.title = L("editor.windowTitle")
        w.center()
        w.isReleasedWhenClosed = false
        w.delegate = self

        let contentView = NSView(frame: w.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]

        // 상단 버튼 영역
        let toolbar = NSView(frame: NSRect(x: 0, y: contentView.bounds.height - 44, width: contentView.bounds.width, height: 44))
        toolbar.autoresizingMask = [.width, .minYMargin]

        lockLabel = NSTextField(labelWithString: L("editor.editPrompt"))
        lockLabel.frame = NSRect(x: 12, y: 10, width: 350, height: 24)
        lockLabel.textColor = .secondaryLabelColor
        lockLabel.font = NSFont.systemFont(ofSize: 12)
        toolbar.addSubview(lockLabel)

        let resetAllBtn = NSButton(title: L("editor.resetAll"), target: self, action: #selector(resetAllMappings))
        resetAllBtn.bezelStyle = .rounded
        resetAllBtn.frame = NSRect(x: contentView.bounds.width - 310, y: 8, width: 100, height: 28)
        resetAllBtn.autoresizingMask = [.minXMargin]
        toolbar.addSubview(resetAllBtn)

        editToggleButton = NSButton(title: L("editor.editEnable"), target: self, action: #selector(toggleEditMode))
        editToggleButton.bezelStyle = .rounded
        editToggleButton.frame = NSRect(x: contentView.bounds.width - 160, y: 8, width: 148, height: 28)
        editToggleButton.autoresizingMask = [.minXMargin]
        toolbar.addSubview(editToggleButton)

        contentView.addSubview(toolbar)

        // 테이블 뷰
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: contentView.bounds.width, height: contentView.bounds.height - 44))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true

        tableView = NSTableView()
        tableView.style = .fullWidth
        tableView.rowSizeStyle = .medium

        let col1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("desc"))
        col1.title = L("editor.column.desc")
        col1.width = 140
        tableView.addTableColumn(col1)

        let col2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("input"))
        col2.title = L("editor.column.input")
        col2.width = 240
        tableView.addTableColumn(col2)

        let col3 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("output"))
        col3.title = L("editor.column.output")
        col3.width = 240
        tableView.addTableColumn(col3)

        tableView.dataSource = self
        tableView.delegate = self

        scrollView.documentView = tableView
        contentView.addSubview(scrollView)

        w.contentView = contentView

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
        self.window = w
    }

    // MARK: - Display 데이터 구축

    private func buildDisplayMappings() {
        displayMappings.removeAll()

        let categories: [(String, [(String, CGKeyCode, ModMask, CGKeyCode, CGEventFlags, MappingScope)])] = [
            (L("category.clipboard"), [
                (L("action.copy"), KeyCode.c, .ctrl, KeyCode.c, cmdFlag, .nonTerminal),
                (L("action.paste"), KeyCode.v, .ctrl, KeyCode.v, cmdFlag, .nonTerminal),
                (L("action.cut"), KeyCode.x, .ctrl, KeyCode.x, cmdFlag, .nonTerminal),
                (L("action.undo"), KeyCode.z, .ctrl, KeyCode.z, cmdFlag, .nonTerminal),
                (L("action.redo"), KeyCode.y, .ctrl, KeyCode.z, flags(cmdFlag, shiftFlag), .nonTerminal),
                (L("action.selectAll"), KeyCode.a, .ctrl, KeyCode.a, cmdFlag, .nonTerminal),
            ]),
            (L("category.file"), [
                (L("action.save"), KeyCode.s, .ctrl, KeyCode.s, cmdFlag, .nonTerminal),
                (L("action.new"), KeyCode.n, .ctrl, KeyCode.n, cmdFlag, .nonTerminal),
                (L("action.open"), KeyCode.o, .ctrl, KeyCode.o, cmdFlag, .nonTerminal),
                (L("action.print"), KeyCode.p, .ctrl, KeyCode.p, cmdFlag, .nonTerminal),
                (L("action.find"), KeyCode.f, .ctrl, KeyCode.f, cmdFlag, .nonTerminal),
                (L("action.findReplace"), KeyCode.h, .ctrl, KeyCode.f, flags(cmdFlag, optFlag), .nonTerminal),
            ]),
            (L("category.browser"), [
                (L("action.newTab"), KeyCode.t, .ctrl, KeyCode.t, cmdFlag, .nonTerminal),
                (L("action.closeTab"), KeyCode.w, .ctrl, KeyCode.w, cmdFlag, .nonTerminal),
                (L("action.restoreTab"), KeyCode.t, [.ctrl, .shift], KeyCode.t, flags(cmdFlag, shiftFlag), .nonTerminal),
                (L("action.refresh"), KeyCode.r, .ctrl, KeyCode.r, cmdFlag, .nonTerminal),
                (L("action.refreshF5"), KeyCode.f5, [], KeyCode.r, cmdFlag, .nonTerminal),
                (L("action.addressBar"), KeyCode.l, .ctrl, KeyCode.l, cmdFlag, .nonTerminal),
            ]),
            (L("category.format"), [
                (L("action.bold"), KeyCode.b, .ctrl, KeyCode.b, cmdFlag, .nonTerminal),
                (L("action.italic"), KeyCode.i, .ctrl, KeyCode.i, cmdFlag, .nonTerminal),
                (L("action.underline"), KeyCode.u, .ctrl, KeyCode.u, cmdFlag, .nonTerminal),
            ]),
            (L("category.system"), [
                (L("action.appSwitch"), KeyCode.tab, .alt, KeyCode.tab, cmdFlag, .global),
                (L("action.appQuit"), KeyCode.f4, .alt, KeyCode.q, cmdFlag, .global),
                (L("action.forceQuit"), KeyCode.escape, [.ctrl, .shift], KeyCode.escape, flags(cmdFlag, optFlag), .global),
                (L("action.lockScreen"), KeyCode.l, .cmd, KeyCode.q, flags(ctrlFlag, cmdFlag), .global),
                (L("action.spotlight"), KeyCode.r, .cmd, KeyCode.space, cmdFlag, .global),
                (L("action.missionControl"), KeyCode.tab, .cmd, KeyCode.upArrow, ctrlFlag, .global),
            ]),
            (L("category.screenshot"), [
                (L("action.screenshotFull"), KeyCode.f13, [], KeyCode.num3, flags(cmdFlag, shiftFlag), .global),
                (L("action.screenshotWindow"), KeyCode.f13, .alt, KeyCode.num4, flags(cmdFlag, shiftFlag), .global),
                (L("action.screenshotArea"), KeyCode.s, [.cmd, .shift], KeyCode.num4, flags(cmdFlag, shiftFlag), .global),
                (L("action.screenshotTool"), KeyCode.f13, .shift, KeyCode.num5, flags(cmdFlag, shiftFlag), .global),
            ]),
            (L("category.navigation"), [
                (L("action.lineStart"), KeyCode.home, [], KeyCode.leftArrow, cmdFlag, .nonTerminal),
                (L("action.lineEnd"), KeyCode.end, [], KeyCode.rightArrow, cmdFlag, .nonTerminal),
                (L("action.wordLeft"), KeyCode.leftArrow, .ctrl, KeyCode.leftArrow, optFlag, .nonTerminal),
                (L("action.wordRight"), KeyCode.rightArrow, .ctrl, KeyCode.rightArrow, optFlag, .nonTerminal),
                (L("action.wordDelete"), KeyCode.backspace, .ctrl, KeyCode.backspace, optFlag, .nonTerminal),
            ]),
            (L("category.finder"), [
                (L("action.rename"), KeyCode.f2, [], KeyCode.returnKey, noFlags, .finderOnly),
                (L("action.open"), KeyCode.returnKey, [], KeyCode.o, cmdFlag, .finderOnly),
                (L("action.trash"), KeyCode.delete, [], KeyCode.backspace, cmdFlag, .finderOnly),
                (L("action.parentFolder"), KeyCode.backspace, [], KeyCode.upArrow, cmdFlag, .finderOnly),
                (L("action.fileInfo"), KeyCode.returnKey, .alt, KeyCode.i, cmdFlag, .finderOnly),
            ]),
        ]

        let customEntries = CustomMappings.shared.allEntries()

        for (category, mappings) in categories {
            // 카테고리 헤더
            displayMappings.append(DisplayMapping(
                category: category, description: "", inputShortcut: "", outputShortcut: "",
                inputKey: 0, inputMods: [],
                outputKey: 0, outputFlags: noFlags,
                scope: .global, isHeader: true, isLanguageToggle: false
            ))
            for (desc, inKey, inMods, outKey, outFlags, scope) in mappings {
                let entryId = "custom_\(inKey)_\(inMods.rawValue)"
                let custom = customEntries.first(where: { $0.id == entryId && $0.enabled })

                // 입력 표시
                var displayInKey = inKey
                var displayInMods = inMods
                var displayHeldKeys: Set<CGKeyCode> = []
                var inputCustomized = false
                var triggerSuffix = ""

                if let c = custom {
                    let customInKey = CGKeyCode(c.inputKeyCode)
                    let customInMods = ModMask(rawValue: c.inputMods)
                    let customHeld = Set(c.inputHeldKeys.map { CGKeyCode($0) })
                    // 입력이 기본값과 다르면 커스텀
                    if customInKey != inKey || customInMods != inMods || !customHeld.isEmpty {
                        displayInKey = customInKey
                        displayInMods = customInMods
                        displayHeldKeys = customHeld
                        inputCustomized = true
                    }
                    if c.triggerOnRelease { triggerSuffix = " ↑" }
                }

                // 자동 접두사 감지에 의한 release trigger 표시
                if !inputCustomized {
                    let allActive = allMappings + CustomMappings.shared.activeMappings()
                    for other in allActive where !other.heldKeys.isEmpty {
                        if other.heldKeys.contains(inKey) && inMods.isSubset(of: other.inputMods) {
                            triggerSuffix = " ↑"
                            break
                        }
                    }
                }

                let inputStr = shortcutName(keyCode: displayInKey, mods: displayInMods, heldKeys: displayHeldKeys)
                    + (inputCustomized ? " ✎" : "") + triggerSuffix

                // Mac 칼럼 표시: 커스텀 Mac 입력이 있으면 커스텀 값 + ✎, 없으면 기본 Mac 단축키(= 출력)
                var macCustomized = false
                let macDisplayStr: String

                if let c = custom, let macKey = c.macInputKeyCode, let macMods = c.macInputMods {
                    let macModMask = ModMask(rawValue: macMods)
                    macDisplayStr = macShortcutName(keyCode: CGKeyCode(macKey), flags: modsToEventFlags(macModMask))
                    macCustomized = true
                } else {
                    macDisplayStr = macShortcutName(keyCode: outKey, flags: outFlags)
                }

                let outputStr = macDisplayStr + (macCustomized ? " ✎" : "")

                displayMappings.append(DisplayMapping(
                    category: category, description: desc,
                    inputShortcut: inputStr, outputShortcut: outputStr,
                    inputKey: inKey, inputMods: inMods,
                    outputKey: outKey, outputFlags: outFlags,
                    scope: scope, isHeader: false, isLanguageToggle: false
                ))
            }
            // 시스템 카테고리 끝에 언어 전환 키 추가
            if category == L("category.system") {
                let langKeyCode = Preferences.shared.languageKeyCode ?? KeyCode.rightOption
                let langKeyName = keyCodeName(langKeyCode)
                let isCustom = Preferences.shared.isLanguageKeyConfigured
                let langInputStr = langKeyName + (isCustom ? " ✎" : "")

                displayMappings.append(DisplayMapping(
                    category: category, description: L("action.languageToggle"),
                    inputShortcut: langInputStr, outputShortcut: L("action.inputSourceToggle"),
                    inputKey: KeyCode.rightOption, inputMods: [],
                    outputKey: 0, outputFlags: noFlags,
                    scope: .global, isHeader: false, isLanguageToggle: true
                ))
            }
        }
    }

    // MARK: - Actions

    @objc private func resetAllMappings() {
        let alert = NSAlert()
        alert.messageText = L("alert.restoreDefaults.title")
        alert.informativeText = L("alert.restoreDefaults.message")
        alert.alertStyle = .warning
        alert.addButton(withTitle: L("alert.restoreDefaults.confirm"))
        alert.addButton(withTitle: L("alert.cancel"))
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        for entry in CustomMappings.shared.allEntries() {
            CustomMappings.shared.remove(id: entry.id)
        }
        KeyRemapper.shared.rebuildTable()
        buildDisplayMappings()
        tableView.reloadData()
    }

    @objc private func toggleEditMode() {
        editEnabled.toggle()
        editToggleButton.title = editEnabled ? L("editor.editLock") : L("editor.editEnable")
        if editEnabled {
            lockLabel.stringValue = L("editor.editWarning")
            lockLabel.textColor = .systemOrange
        } else {
            lockLabel.stringValue = L("editor.editPrompt")
            lockLabel.textColor = .secondaryLabelColor
        }
        tableView.reloadData()
    }

    @objc private func editInputMapping(_ sender: NSButton) {
        let row = sender.tag
        guard row >= 0 && row < displayMappings.count else { return }
        let mapping = displayMappings[row]
        if mapping.isLanguageToggle {
            showKeyRecorder(for: mapping, mode: .languageKey)
        } else {
            showKeyRecorder(for: mapping, mode: .input)
        }
    }

    @objc private func editOutputMapping(_ sender: NSButton) {
        let row = sender.tag
        guard row >= 0 && row < displayMappings.count else { return }
        showKeyRecorder(for: displayMappings[row], mode: .macInput)
    }

    // MARK: - 멀티키 레코더

    private var recorderPanel: NSPanel?
    private var recorderLocalMonitor: Any?
    private var recorderGlobalMonitor: Any?
    private var currentRecordingMapping: DisplayMapping?
    private var recordingMode: RecordingMode = .input

    // 레코더 상태 머신
    private var recorderPressedKeys = Set<CGKeyCode>()
    private var recorderMaxKeys = Set<CGKeyCode>()
    private var recorderKeyOrder: [CGKeyCode] = []
    private var recorderPeakMods = ModMask()
    private var recorderCurrentMods = ModMask()
    private var recorderLabel: NSTextField?

    private func showKeyRecorder(for mapping: DisplayMapping, mode: RecordingMode) {
        currentRecordingMapping = mapping
        recordingMode = mode

        // 레코더 상태 초기화
        recorderPressedKeys.removeAll()
        recorderMaxKeys.removeAll()
        recorderKeyOrder.removeAll()
        recorderPeakMods = []
        recorderCurrentMods = []

        // 이벤트 탭 일시 중지
        EventTapManager.shared.stop()

        let modeTitle = mode == .input ? L("alert.shortcutConfirm.inputTitle") : L("alert.shortcutConfirm.macTitle")
        let currentStr = mode == .input ? mapping.inputShortcut : mapping.outputShortcut

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "\(modeTitle): \(mapping.description)"
        panel.level = .floating
        panel.center()
        panel.isReleasedWhenClosed = false

        let contentView = NSView(frame: panel.contentView!.bounds)

        let labelText = mode == .input
            ? L("alert.recorder.inputPrompt", mapping.description, currentStr)
            : L("alert.recorder.macPrompt", mapping.description, currentStr)
        let label = NSTextField(wrappingLabelWithString: labelText)
        label.frame = NSRect(x: 30, y: 90, width: 340, height: 80)
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 14)
        contentView.addSubview(label)
        recorderLabel = label

        let cancelBtn = NSButton(title: L("alert.cancel"), target: self, action: #selector(recorderCancel))
        cancelBtn.bezelStyle = .rounded
        cancelBtn.frame = NSRect(x: 100, y: 15, width: 80, height: 28)
        contentView.addSubview(cancelBtn)

        let resetBtn = NSButton(title: L("alert.default"), target: self, action: #selector(recorderReset))
        resetBtn.bezelStyle = .rounded
        resetBtn.frame = NSRect(x: 220, y: 15, width: 80, height: 28)
        contentView.addSubview(resetBtn)

        panel.contentView = contentView
        panel.makeKeyAndOrderFront(nil)
        recorderPanel = panel

        // 로컬 모니터 — 모든 키 이벤트 가로챔 (nil 반환 = 전달 차단)
        recorderLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            guard let self = self else { return event }
            if event.type == .flagsChanged {
                self.recorderHandleFlags(event)
                return nil
            }
            let kc = CGKeyCode(event.keyCode)
            if event.type == .keyDown {
                if kc == KeyCode.escape && self.recorderPressedKeys.isEmpty && self.recorderCurrentMods == [] {
                    self.cleanupRecorder()
                    return nil
                }
                self.recorderKeyDown(kc)
            } else if event.type == .keyUp {
                self.recorderKeyUp(kc)
            }
            return nil
        }

        // 글로벌 모니터
        recorderGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .keyUp, .flagsChanged]) { [weak self] event in
            guard let self = self else { return }
            if event.type == .flagsChanged {
                self.recorderHandleFlags(event)
                return
            }
            let kc = CGKeyCode(event.keyCode)
            if event.type == .keyDown {
                self.recorderKeyDown(kc)
            } else if event.type == .keyUp {
                self.recorderKeyUp(kc)
            }
        }
    }

    private func recorderHandleFlags(_ event: NSEvent) {
        let kc = CGKeyCode(event.keyCode)

        // 언어 전환 키 모드: 수식키도 단일 키로 즉시 확정
        if recordingMode == .languageKey && isModifierKey(kc) {
            // 키 다운인지 확인 (새로 눌린 경우)
            let isDown = isModifierKeyDown(kc, event.modifierFlags)
            if isDown {
                handleRecordedLanguageKey(kc)
                return
            }
        }

        var mods = ModMask()
        if event.modifierFlags.contains(.control) { mods.insert(.ctrl) }
        if event.modifierFlags.contains(.option) { mods.insert(.alt) }
        if event.modifierFlags.contains(.shift) { mods.insert(.shift) }
        if event.modifierFlags.contains(.command) { mods.insert(.cmd) }
        recorderCurrentMods = mods
        if mods.rawValue > recorderPeakMods.rawValue {
            recorderPeakMods = mods
        }
        updateRecorderDisplay()
        if recorderPressedKeys.isEmpty && mods == [] && !recorderMaxKeys.isEmpty {
            finalizeRecording()
        }
    }

    private func isModifierKeyDown(_ keyCode: CGKeyCode, _ flags: NSEvent.ModifierFlags) -> Bool {
        switch keyCode {
        case KeyCode.option, KeyCode.rightOption: return flags.contains(.option)
        case KeyCode.control, KeyCode.rightControl: return flags.contains(.control)
        case KeyCode.shift, KeyCode.rightShift: return flags.contains(.shift)
        case KeyCode.command, KeyCode.rightCommand: return flags.contains(.command)
        default: return false
        }
    }

    private func recorderKeyDown(_ keyCode: CGKeyCode) {
        if isModifierKey(keyCode) { return }

        // 언어 전환 키 모드: 일반 키도 즉시 확정
        if recordingMode == .languageKey {
            handleRecordedLanguageKey(keyCode)
            return
        }

        recorderPressedKeys.insert(keyCode)
        recorderMaxKeys.insert(keyCode)
        if !recorderKeyOrder.contains(keyCode) {
            recorderKeyOrder.append(keyCode)
        }
        if recorderCurrentMods.rawValue > recorderPeakMods.rawValue {
            recorderPeakMods = recorderCurrentMods
        }
        updateRecorderDisplay()
    }

    private func recorderKeyUp(_ keyCode: CGKeyCode) {
        if isModifierKey(keyCode) { return }
        recorderPressedKeys.remove(keyCode)
        if recorderPressedKeys.isEmpty && recorderCurrentMods == [] && !recorderMaxKeys.isEmpty {
            finalizeRecording()
        }
    }

    private func isModifierKey(_ keyCode: CGKeyCode) -> Bool {
        switch keyCode {
        case KeyCode.command, KeyCode.rightCommand,
             KeyCode.option, KeyCode.rightOption,
             KeyCode.control, KeyCode.rightControl,
             KeyCode.shift, KeyCode.rightShift,
             KeyCode.capsLock:
            return true
        default:
            return false
        }
    }

    // MARK: - 언어 전환 키 저장

    private func handleRecordedLanguageKey(_ keyCode: CGKeyCode) {
        let keyName = keyCodeName(keyCode)

        let alert = NSAlert()
        alert.messageText = L("alert.langKey.title")
        alert.informativeText = L("alert.langKey.message", keyName)
        alert.alertStyle = .informational
        alert.addButton(withTitle: L("alert.set"))
        alert.addButton(withTitle: L("alert.reenter"))
        alert.addButton(withTitle: L("alert.cancel"))

        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            // 다시 입력 — 상태 유지
            return
        }
        if response == .alertThirdButtonReturn {
            cleanupRecorder()
            return
        }

        Preferences.shared.languageKeyCode = keyCode
        cleanupRecorder()
    }

    private func updateRecorderDisplay() {
        guard let label = recorderLabel, let mapping = currentRecordingMapping else { return }
        var parts: [String] = []

        if recordingMode == .macInput {
            // Mac 스타일 수식키 이름
            let modStr = macModName(modsToEventFlags(recorderCurrentMods))
            if !modStr.isEmpty { parts.append(modStr) }
        } else {
            let modStr = modMaskName(recorderCurrentMods)
            if !modStr.isEmpty { parts.append(modStr) }
        }

        for kc in recorderKeyOrder where recorderPressedKeys.contains(kc) {
            parts.append(keyCodeName(kc))
        }
        let current = parts.isEmpty ? "..." : parts.joined(separator: "+")
        switch recordingMode {
        case .input:
            label.stringValue = L("alert.recorder.inputRecording", mapping.description, current)
        case .macInput:
            label.stringValue = L("alert.recorder.macRecording", mapping.description, current)
        case .languageKey:
            label.stringValue = L("alert.recorder.langRecording", mapping.description, current)
        }
    }

    private func finalizeRecording() {
        guard let mapping = currentRecordingMapping else { return }

        let nonModKeys = recorderKeyOrder.filter { recorderMaxKeys.contains($0) }

        if nonModKeys.isEmpty {
            let alert = NSAlert()
            alert.messageText = L("alert.shortcutError.title")
            alert.informativeText = L("alert.shortcutError.message")
            alert.alertStyle = .warning
            alert.addButton(withTitle: L("alert.confirm"))
            alert.runModal()
            resetRecorderState()
            return
        }

        let mods = recorderPeakMods
        let triggerKey: CGKeyCode
        var heldKeys: Set<CGKeyCode> = []

        if recordingMode == .macInput {
            triggerKey = nonModKeys.last!
        } else {
            if nonModKeys.count >= 2 {
                triggerKey = nonModKeys.last!
                heldKeys = Set(nonModKeys.dropLast().map { $0 })
            } else {
                triggerKey = nonModKeys[0]
            }
        }

        // 확인 대화상자: 설정할 단축키를 보여주고 확인
        let displayName: String
        if recordingMode == .macInput {
            displayName = macShortcutName(keyCode: triggerKey, flags: modsToEventFlags(mods))
        } else {
            displayName = shortcutName(keyCode: triggerKey, mods: mods, heldKeys: heldKeys)
        }

        let alert = NSAlert()
        alert.messageText = recordingMode == .input
            ? L("alert.shortcutConfirm.inputTitle")
            : L("alert.shortcutConfirm.macTitle")
        alert.informativeText = recordingMode == .input
            ? L("alert.shortcutConfirm.inputMessage", mapping.description, displayName)
            : L("alert.shortcutConfirm.macMessage", mapping.description, displayName)
        alert.alertStyle = .informational
        alert.addButton(withTitle: L("alert.set"))
        alert.addButton(withTitle: L("alert.reenter"))
        alert.addButton(withTitle: L("alert.cancel"))

        let response = alert.runModal()
        if response == .alertSecondButtonReturn {
            // 다시 입력
            resetRecorderState()
            return
        }
        if response == .alertThirdButtonReturn {
            // 취소
            cleanupRecorder()
            return
        }

        // 설정 진행
        if recordingMode == .macInput {
            handleRecordedMacInput(triggerKey, mods)
        } else {
            handleRecordedInput(triggerKey, mods, heldKeys: heldKeys)
        }
    }

    // MARK: - 입력 단축키 저장

    private func handleRecordedInput(_ keyCode: CGKeyCode, _ mods: ModMask, heldKeys: Set<CGKeyCode>) {
        guard let mapping = currentRecordingMapping else { return }

        let entryId = "custom_\(mapping.inputKey)_\(mapping.inputMods.rawValue)"
        let heldKeysArray = heldKeys.sorted().map { UInt16($0) }

        // 충돌 검사
        if let conflict = CustomMappings.shared.findConflict(
            inputKeyCode: UInt16(keyCode), inputMods: mods.rawValue,
            inputHeldKeys: heldKeysArray, excludeId: entryId
        ) {
            showConflictAlert(conflict)
            return
        }

        // macOS 충돌 검사
        if let macConflict = CustomMappings.shared.findMacOSConflict(keyCode: UInt16(keyCode), mods: mods.rawValue) {
            let alert = NSAlert()
            alert.messageText = L("alert.macConflict.title")
            alert.informativeText = L("alert.macConflict.message", macConflict)
            alert.alertStyle = .warning
            alert.addButton(withTitle: L("alert.change"))
            alert.addButton(withTitle: L("alert.cancel"))
            guard alert.runModal() == .alertFirstButtonReturn else {
                resetRecorderState()
                return
            }
        }

        // 기존 커스텀 엔트리에서 출력 값 및 Mac 필드 보존
        let existing = CustomMappings.shared.allEntries().first(where: { $0.id == entryId })
        let outKey = existing?.outputKeyCode ?? UInt16(mapping.outputKey)
        let outFlags = existing?.outputFlags ?? mapping.outputFlags.rawValue

        let entry = CustomMappingEntry(
            id: entryId,
            description: mapping.description,
            inputKeyCode: UInt16(keyCode),
            inputMods: mods.rawValue,
            inputHeldKeys: heldKeysArray,
            triggerOnRelease: false,
            outputKeyCode: outKey,
            outputFlags: outFlags,
            scopeRaw: scopeRawValue(mapping.scope),
            enabled: true,
            macInputKeyCode: existing?.macInputKeyCode,
            macInputMods: existing?.macInputMods
        )
        CustomMappings.shared.addOrUpdate(entry)
        KeyRemapper.shared.rebuildTable()
        cleanupRecorder()
    }

    // MARK: - Mac 모드 입력 단축키 저장

    private func handleRecordedMacInput(_ keyCode: CGKeyCode, _ mods: ModMask) {
        guard let mapping = currentRecordingMapping else { return }

        let entryId = "custom_\(mapping.inputKey)_\(mapping.inputMods.rawValue)"

        // Mac 입력 충돌 검사 (Mac-Mac 중복 + Mac커스텀 vs Mac기본)
        if let conflict = CustomMappings.shared.findMacConflict(
            keyCode: UInt16(keyCode), mods: mods.rawValue, excludeId: entryId
        ) {
            showConflictAlert(conflict)
            return
        }

        // macOS 기본 단축키 충돌 경고
        if let macConflict = CustomMappings.shared.findMacOSConflict(keyCode: UInt16(keyCode), mods: mods.rawValue) {
            let alert = NSAlert()
            alert.messageText = L("alert.macConflict.title")
            alert.informativeText = L("alert.macConflict.message", macConflict)
            alert.alertStyle = .warning
            alert.addButton(withTitle: L("alert.change"))
            alert.addButton(withTitle: L("alert.cancel"))
            guard alert.runModal() == .alertFirstButtonReturn else {
                resetRecorderState()
                return
            }
        }

        // 기존 커스텀 엔트리에서 Windows 입력 값 보존
        let existing = CustomMappings.shared.allEntries().first(where: { $0.id == entryId })
        let inKey = existing?.inputKeyCode ?? UInt16(mapping.inputKey)
        let inMods = existing?.inputMods ?? mapping.inputMods.rawValue
        let inHeld = existing?.inputHeldKeys ?? []
        let trigRelease = existing?.triggerOnRelease ?? false
        let outKey = existing?.outputKeyCode ?? UInt16(mapping.outputKey)
        let outFlags = existing?.outputFlags ?? mapping.outputFlags.rawValue

        let entry = CustomMappingEntry(
            id: entryId,
            description: mapping.description,
            inputKeyCode: inKey,
            inputMods: inMods,
            inputHeldKeys: inHeld,
            triggerOnRelease: trigRelease,
            outputKeyCode: outKey,
            outputFlags: outFlags,
            scopeRaw: scopeRawValue(mapping.scope),
            enabled: true,
            macInputKeyCode: UInt16(keyCode),
            macInputMods: mods.rawValue
        )
        CustomMappings.shared.addOrUpdate(entry)
        KeyRemapper.shared.rebuildTable()
        cleanupRecorder()
    }

    // MARK: - 헬퍼

    private func modsToEventFlags(_ mods: ModMask) -> CGEventFlags {
        var f = CGEventFlags()
        if mods.contains(.ctrl) { f.insert(.maskControl) }
        if mods.contains(.alt) { f.insert(.maskAlternate) }
        if mods.contains(.shift) { f.insert(.maskShift) }
        if mods.contains(.cmd) { f.insert(.maskCommand) }
        return f
    }

    private func scopeRawValue(_ scope: MappingScope) -> Int {
        switch scope {
        case .global: return 0
        case .nonTerminal: return 1
        case .finderOnly: return 2
        }
    }

    private func showConflictAlert(_ conflict: String) {
        let alert = NSAlert()
        alert.messageText = L("alert.conflict.title")
        alert.informativeText = L("alert.conflict.message", conflict)
        alert.alertStyle = .warning
        alert.addButton(withTitle: L("alert.confirm"))
        alert.runModal()
        resetRecorderState()
    }

    private func resetRecorderState() {
        recorderMaxKeys.removeAll()
        recorderKeyOrder.removeAll()
        recorderPeakMods = []
    }

    @objc private func recorderCancel() {
        cleanupRecorder()
    }

    @objc private func recorderReset() {
        guard let mapping = currentRecordingMapping else { cleanupRecorder(); return }
        if mapping.isLanguageToggle {
            // 언어 전환 키를 기본값(Right Alt)으로 복원
            Preferences.shared.languageKeyCode = nil
        } else if recordingMode == .macInput {
            // Mac 입력만 기본값으로 초기화
            let entryId = "custom_\(mapping.inputKey)_\(mapping.inputMods.rawValue)"
            if let existing = CustomMappings.shared.allEntries().first(where: { $0.id == entryId }) {
                // Windows 입력이 기본값이면 엔트리 자체 삭제
                let winInputIsDefault = existing.inputKeyCode == UInt16(mapping.inputKey)
                    && existing.inputMods == mapping.inputMods.rawValue
                    && existing.inputHeldKeys.isEmpty
                if winInputIsDefault {
                    CustomMappings.shared.remove(id: entryId)
                } else {
                    // Mac 필드만 nil로 업데이트
                    let entry = CustomMappingEntry(
                        id: entryId,
                        description: existing.description,
                        inputKeyCode: existing.inputKeyCode,
                        inputMods: existing.inputMods,
                        inputHeldKeys: existing.inputHeldKeys,
                        triggerOnRelease: existing.triggerOnRelease,
                        outputKeyCode: existing.outputKeyCode,
                        outputFlags: existing.outputFlags,
                        scopeRaw: existing.scopeRaw,
                        enabled: existing.enabled,
                        macInputKeyCode: nil,
                        macInputMods: nil
                    )
                    CustomMappings.shared.addOrUpdate(entry)
                }
            }
            KeyRemapper.shared.rebuildTable()
        } else {
            // Windows 입력 기본값 초기화
            let entryId = "custom_\(mapping.inputKey)_\(mapping.inputMods.rawValue)"
            if let existing = CustomMappings.shared.allEntries().first(where: { $0.id == entryId }) {
                // Mac 입력이 커스텀이면 Mac 필드만 보존하고 Windows 입력을 기본값으로
                if existing.macInputKeyCode != nil {
                    let entry = CustomMappingEntry(
                        id: entryId,
                        description: existing.description,
                        inputKeyCode: UInt16(mapping.inputKey),
                        inputMods: mapping.inputMods.rawValue,
                        inputHeldKeys: [],
                        triggerOnRelease: false,
                        outputKeyCode: existing.outputKeyCode,
                        outputFlags: existing.outputFlags,
                        scopeRaw: existing.scopeRaw,
                        enabled: existing.enabled,
                        macInputKeyCode: existing.macInputKeyCode,
                        macInputMods: existing.macInputMods
                    )
                    CustomMappings.shared.addOrUpdate(entry)
                } else {
                    CustomMappings.shared.remove(id: entryId)
                }
            }
            KeyRemapper.shared.rebuildTable()
        }
        cleanupRecorder()
    }

    private func cleanupRecorder() {
        if let m = recorderLocalMonitor { NSEvent.removeMonitor(m); recorderLocalMonitor = nil }
        if let m = recorderGlobalMonitor { NSEvent.removeMonitor(m); recorderGlobalMonitor = nil }
        recorderPanel?.close()
        recorderPanel = nil
        currentRecordingMapping = nil
        recorderLabel = nil
        recorderPressedKeys.removeAll()
        recorderMaxKeys.removeAll()
        recorderKeyOrder.removeAll()
        recorderPeakMods = []
        recorderCurrentMods = []
        _ = EventTapManager.shared.start()
        buildDisplayMappings()
        tableView.reloadData()
    }

    // MARK: - NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        displayMappings.count
    }

    // MARK: - NSTableViewDelegate

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let mapping = displayMappings[row]

        if mapping.isHeader {
            let cell = NSTextField(labelWithString: mapping.category)
            cell.font = NSFont.boldSystemFont(ofSize: 12)
            cell.textColor = .secondaryLabelColor
            return cell
        }

        let id = tableColumn?.identifier.rawValue ?? ""

        switch id {
        case "desc":
            let cell = NSTextField(labelWithString: mapping.description)
            cell.font = NSFont.systemFont(ofSize: 13)
            return cell

        case "input":
            if editEnabled {
                return makeCellWithButton(
                    text: mapping.inputShortcut,
                    buttonTitle: L("editor.change"),
                    action: #selector(editInputMapping(_:)),
                    row: row,
                    columnWidth: 240
                )
            }
            let cell = NSTextField(labelWithString: mapping.inputShortcut)
            cell.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            return cell

        case "output":
            if editEnabled && !mapping.isLanguageToggle {
                return makeCellWithButton(
                    text: mapping.outputShortcut,
                    buttonTitle: L("editor.change"),
                    action: #selector(editOutputMapping(_:)),
                    row: row,
                    columnWidth: 240
                )
            }
            let cell = NSTextField(labelWithString: mapping.outputShortcut)
            cell.font = mapping.isLanguageToggle
                ? NSFont.systemFont(ofSize: 12) // 액션 이름은 일반 폰트
                : NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            return cell

        default:
            return nil
        }
    }

    /// 텍스트 + [변경] 버튼이 포함된 셀 생성
    private func makeCellWithButton(
        text: String, buttonTitle: String, action: Selector,
        row: Int, columnWidth: CGFloat, textColor: NSColor = .labelColor
    ) -> NSView {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: columnWidth, height: 24))

        let label = NSTextField(labelWithString: text)
        label.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = textColor
        label.frame = NSRect(x: 0, y: 2, width: columnWidth - 52, height: 20)
        label.lineBreakMode = .byTruncatingTail
        container.addSubview(label)

        let btn = NSButton(title: buttonTitle, target: self, action: action)
        btn.bezelStyle = .rounded
        btn.controlSize = .mini
        btn.font = NSFont.systemFont(ofSize: 10)
        btn.tag = row
        btn.frame = NSRect(x: columnWidth - 50, y: 1, width: 46, height: 20)
        container.addSubview(btn)

        return container
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        displayMappings[row].isHeader ? 28 : 24
    }

    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        displayMappings[row].isHeader
    }
}

extension MappingEditorWindow: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        window = nil
    }
}
