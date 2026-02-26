import CoreGraphics
import AppKit
import Carbon

final class KeyRemapper {
    static let shared = KeyRemapper()

    // pressTable: keyDown에서 조회 (triggerOnRelease=false) — Windows 모드
    // releaseTable: keyUp에서 조회 (triggerOnRelease=true) — Windows 모드
    private var pressTable: [UInt64: [KeyMapping]] = [:]
    private var releaseTable: [UInt64: [KeyMapping]] = [:]

    // Mac 모드용 매핑 테이블 (단순 구조: heldKeys 없음, prefix 분석 불필요)
    private var macPressTable: [UInt64: [KeyMapping]] = [:]
    private var macReleaseTable: [UInt64: [KeyMapping]] = [:]

    // 현재 눌린 비수식키 추적
    private var heldNonModKeys = Set<CGKeyCode>()
    // 콤보에 사용된 키 (keyUp 억제용)
    private var comboConsumedKeys = Set<CGKeyCode>()
    // keyDown에서 리매핑된 키 추적 (keyUp에서도 같은 리매핑 적용)
    private var activeRemaps: [CGKeyCode: KeyMapping] = [:]

    // Alt+Tab 상태 추적
    private var altTabActive = false

    init() {
        rebuildTable()
    }

    func rebuildTable() {
        pressTable.removeAll()
        releaseTable.removeAll()
        macPressTable.removeAll()
        macReleaseTable.removeAll()

        // === Windows 모드 테이블 구축 ===

        // 1. 모든 활성 매핑 수집
        var allActive: [KeyMapping] = Array(allMappings)
        let customMappings = CustomMappings.shared.activeMappings()

        // 커스텀 매핑은 기존 매핑을 오버라이드
        for custom in customMappings {
            allActive.insert(custom, at: 0)
        }

        // 2. 접두사 관계 분석: A의 triggerKey가 B의 heldKeys에 포함되면 A는 접두사
        //    → A를 triggerOnRelease=true로 자동 전환
        var prefixKeys = Set<UInt64>() // release로 전환해야 할 매핑의 lookupKey
        for b in allActive where !b.heldKeys.isEmpty {
            for a in allActive where a.heldKeys.isEmpty {
                if b.heldKeys.contains(a.inputKey)
                    && a.inputMods.isSubset(of: b.inputMods) {
                    prefixKeys.insert(lookupKey(a.inputKey, a.inputMods))
                }
            }
        }

        // 3. pressTable / releaseTable 분리 구축
        for mapping in allActive {
            let key = lookupKey(mapping.inputKey, mapping.inputMods)
            let shouldRelease = mapping.triggerOnRelease || prefixKeys.contains(key)

            if shouldRelease {
                // release 버전으로 변환
                let relMapping = KeyMapping(
                    mapping.inputKey, mapping.inputMods,
                    mapping.outputKey, mapping.outputFlags,
                    scope: mapping.scope,
                    heldKeys: mapping.heldKeys,
                    triggerOnRelease: true
                )
                releaseTable[key, default: []].append(relMapping)
            } else {
                pressTable[key, default: []].append(mapping)
            }

            // heldKeys가 있는 매핑은 항상 pressTable에도 넣음
            if !mapping.heldKeys.isEmpty && !shouldRelease {
                // 이미 위에서 추가됨
            } else if !mapping.heldKeys.isEmpty && shouldRelease {
                // heldKeys가 있으면서 release인 경우: releaseTable에만
            }
        }

        // === Mac 모드 테이블 구축 (단순: heldKeys 없음, prefix 분석 불필요) ===
        let macMappings = CustomMappings.shared.activeMacMappings()
        for mapping in macMappings {
            let key = lookupKey(mapping.inputKey, mapping.inputMods)
            if mapping.triggerOnRelease {
                macReleaseTable[key, default: []].append(mapping)
            } else {
                macPressTable[key, default: []].append(mapping)
            }
        }
    }

    private func lookupKey(_ keyCode: CGKeyCode, _ mods: ModMask) -> UInt64 {
        UInt64(keyCode) | (UInt64(mods.rawValue) << 32)
    }

    /// releaseTable에만 있는지 확인 (pressTable에는 없음)
    private func isReleaseTriggerOnly(_ keyCode: CGKeyCode, _ mods: ModMask) -> Bool {
        let key = lookupKey(keyCode, mods)
        return releaseTable[key] != nil && pressTable[key] == nil
    }

    func processKeyEvent(_ event: CGEvent, type: CGEventType) -> CGEvent? {
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let eventFlags = event.flags

        // keyUp 처리
        if type == .keyUp {
            defer {
                heldNonModKeys.remove(keyCode)
                comboConsumedKeys.remove(keyCode)
            }

            // Alt+Tab keyUp
            if altTabActive && keyCode == KeyCode.tab {
                let nonModFlags = eventFlags.subtracting([.maskCommand, .maskAlternate, .maskControl, .maskShift])
                event.flags = CGEventFlags.maskCommand.union(nonModFlags)
                return event
            }

            // Mac 모드: macReleaseTable 조회, 없으면 패스스루
            if !Preferences.shared.isWindowsMode {
                let currentMods = extractModMask(from: eventFlags)
                let key = lookupKey(keyCode, currentMods)
                if let mappings = macReleaseTable[key] {
                    if let result = tryApplyMapping(mappings, event: event, eventFlags: eventFlags) {
                        return result
                    }
                }
                return event
            }

            let currentMods = extractModMask(from: eventFlags)

            // comboConsumedKeys에 있으면 keyUp 억제 (이미 콤보의 held로 사용됨)
            if comboConsumedKeys.contains(keyCode) {
                return nil
            }

            // releaseTable 조회
            let key = lookupKey(keyCode, currentMods)
            if let mappings = releaseTable[key] {
                if let result = tryApplyMapping(mappings, event: event, eventFlags: eventFlags) {
                    return result
                }
            }

            // keyDown에서 리매핑된 키는 keyUp에서도 동일하게 리매핑
            if let remap = activeRemaps.removeValue(forKey: keyCode) {
                event.setIntegerValueField(.keyboardEventKeycode, value: Int64(remap.outputKey))
                let nonModifierFlags = eventFlags.subtracting([.maskCommand, .maskAlternate, .maskControl, .maskShift, .maskSecondaryFn])
                event.flags = remap.outputFlags.union(nonModifierFlags)
                return event
            }

            return event
        }

        guard type == .keyDown else { return event }

        // 키 반복 감지: 이미 눌려있는 키면 반복
        let isRepeat = heldNonModKeys.contains(keyCode)
        heldNonModKeys.insert(keyCode)

        // 모드 전환 단축키 (항상 동작)
        if let modeResult = checkModeToggle(keyCode: keyCode, flags: eventFlags) {
            return modeResult
        }

        // 언어 전환 키
        if let langKeyCode = Preferences.shared.languageKeyCode, keyCode == langKeyCode {
            InputSourceToggle.toggle()
            return nil
        }

        // Mac 모드: macPressTable 조회, 없으면 패스스루
        if !Preferences.shared.isWindowsMode {
            let currentMods = extractModMask(from: eventFlags)
            let key = lookupKey(keyCode, currentMods)
            if let mappings = macPressTable[key] {
                if let result = tryApplyMapping(mappings, event: event, eventFlags: eventFlags) {
                    return result
                }
            }
            return event
        }

        let currentMods = extractModMask(from: eventFlags)

        // --- 특수 처리 ---

        // Alt+Tab 활성 중 Tab 반복
        if altTabActive && keyCode == KeyCode.tab {
            let nonModFlags = eventFlags.subtracting([.maskCommand, .maskAlternate, .maskControl, .maskShift])
            if currentMods.contains(.shift) {
                event.flags = CGEventFlags([.maskCommand, .maskShift]).union(nonModFlags)
            } else {
                event.flags = CGEventFlags.maskCommand.union(nonModFlags)
            }
            return event
        }

        // Win+D → 바탕화면 보기
        if keyCode == KeyCode.d && currentMods == .cmd {
            showDesktop()
            return nil
        }

        // Win+E → Finder 열기
        if keyCode == KeyCode.e && currentMods == .cmd {
            openFinder()
            return nil
        }

        // release-only인 매핑의 키가 눌렸을 때: keyDown 억제 (keyUp에서 발동)
        if !isRepeat && isReleaseTriggerOnly(keyCode, currentMods) {
            return nil
        }

        // --- pressTable 조회 ---
        let key = lookupKey(keyCode, currentMods)
        if let mappings = pressTable[key] {
            if let result = tryApplyMapping(mappings, event: event, eventFlags: eventFlags) {
                return result
            }
        }

        return event
    }

    /// 매핑 배열에서 heldKeys가 가장 많이 일치하는 것 우선 (최장 매치)
    private func tryApplyMapping(_ mappings: [KeyMapping], event: CGEvent, eventFlags: CGEventFlags) -> CGEvent?? {
        let detector = AppDetector.shared
        let isTerminal = detector.isTerminalApp
        let isFinder = detector.isFinderApp

        // heldKeys 개수 내림차순 정렬 (최장 매치 우선)
        let sorted = mappings.sorted { $0.heldKeys.count > $1.heldKeys.count }

        for mapping in sorted {
            // scope 필터
            switch mapping.scope {
            case .global:
                break
            case .nonTerminal:
                if isTerminal { continue }
            case .finderOnly:
                if !isFinder { continue }
            }

            // heldKeys 조건 확인: 모든 heldKeys가 현재 눌려있어야 함
            if !mapping.heldKeys.isEmpty {
                guard mapping.heldKeys.isSubset(of: heldNonModKeys) else { continue }
                // 매칭된 heldKeys를 comboConsumedKeys에 추가
                comboConsumedKeys.formUnion(mapping.heldKeys)
            }

            // Alt+Tab 특수 처리
            if mapping.inputKey == KeyCode.tab && mapping.inputMods == .alt
                && mapping.outputKey == KeyCode.tab && mapping.outputFlags == cmdFlag {
                startAltTab()
                let nonModFlags = eventFlags.subtracting([.maskCommand, .maskAlternate, .maskControl, .maskShift])
                event.setIntegerValueField(.keyboardEventKeycode, value: Int64(KeyCode.tab))
                event.flags = CGEventFlags.maskCommand.union(nonModFlags)
                return .some(event)
            }

            // 스크린샷 특수 처리 (직접 키 전송이 필요한 것들)
            if mapping.inputKey == KeyCode.f13 {
                if mapping.inputMods == .alt {
                    screenshotWindow()
                    return .some(nil)
                }
                if mapping.inputMods == .shift {
                    postKey(key: KeyCode.num5, flags: [.maskCommand, .maskShift])
                    return .some(nil)
                }
                if mapping.inputMods == [] {
                    postKey(key: KeyCode.num3, flags: [.maskCommand, .maskShift])
                    return .some(nil)
                }
            }

            if mapping.inputKey == KeyCode.s && mapping.inputMods == [.cmd, .shift]
                && mapping.outputKey == KeyCode.num4 {
                postKey(key: KeyCode.num4, flags: [.maskCommand, .maskShift])
                return .some(nil)
            }

            // 일반 매핑 적용
            event.setIntegerValueField(.keyboardEventKeycode, value: Int64(mapping.outputKey))
            let nonModifierFlags = eventFlags.subtracting([.maskCommand, .maskAlternate, .maskControl, .maskShift, .maskSecondaryFn])
            event.flags = mapping.outputFlags.union(nonModifierFlags)
            // keyUp에서도 동일하게 리매핑하기 위해 기록
            activeRemaps[mapping.inputKey] = mapping
            return .some(event)
        }

        return nil
    }

    func processFlagsChanged(_ event: CGEvent) -> CGEvent? {
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let eventFlags = event.flags

        if let langKeyCode = Preferences.shared.languageKeyCode, keyCode == langKeyCode {
            let isDown = isModifierKeyDown(keyCode: keyCode, flags: eventFlags)
            if isDown { InputSourceToggle.toggle() }
            return nil
        }

        guard Preferences.shared.isWindowsMode else { return event }

        if altTabActive {
            if keyCode == KeyCode.option || keyCode == KeyCode.rightOption {
                if !eventFlags.contains(.maskAlternate) {
                    endAltTab()
                    return nil
                }
            }
        }

        return event
    }

    // MARK: - Alt+Tab

    private func startAltTab() {
        guard !altTabActive else { return }
        altTabActive = true
        let source = CGEventSource(stateID: .hidSystemState)
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: KeyCode.command, keyDown: true)
        cmdDown?.flags = .maskCommand
        cmdDown?.post(tap: .cghidEventTap)
    }

    private func endAltTab() {
        guard altTabActive else { return }
        altTabActive = false
        let source = CGEventSource(stateID: .hidSystemState)
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: KeyCode.command, keyDown: false)
        cmdUp?.flags = []
        cmdUp?.post(tap: .cghidEventTap)
    }

    // MARK: - 스크린샷

    private func screenshotWindow() {
        postKey(key: KeyCode.num4, flags: [.maskCommand, .maskShift])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.postKey(key: KeyCode.space, flags: [])
        }
    }

    // MARK: - 키 이벤트 전송

    func postKey(key: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
        keyDown?.flags = flags
        keyUp?.flags = flags
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    // MARK: - Helpers

    private func isModifierKeyDown(keyCode: CGKeyCode, flags: CGEventFlags) -> Bool {
        switch keyCode {
        case KeyCode.option, KeyCode.rightOption: return flags.contains(.maskAlternate)
        case KeyCode.control, KeyCode.rightControl: return flags.contains(.maskControl)
        case KeyCode.shift, KeyCode.rightShift: return flags.contains(.maskShift)
        case KeyCode.command, KeyCode.rightCommand: return flags.contains(.maskCommand)
        default: return false
        }
    }

    private func extractModMask(from flags: CGEventFlags) -> ModMask {
        var mask = ModMask()
        if flags.contains(.maskControl) { mask.insert(.ctrl) }
        if flags.contains(.maskAlternate) { mask.insert(.alt) }
        if flags.contains(.maskShift) { mask.insert(.shift) }
        if flags.contains(.maskCommand) { mask.insert(.cmd) }
        return mask
    }

    private func checkModeToggle(keyCode: CGKeyCode, flags: CGEventFlags) -> CGEvent?? {
        let required: CGEventFlags = [.maskControl, .maskAlternate, .maskShift]
        guard flags.contains(required) else { return nil }
        if keyCode == KeyCode.w {
            Preferences.shared.isWindowsMode = true
            NotificationCenter.default.post(name: .modeChanged, object: nil)
            return .some(nil)
        }
        if keyCode == KeyCode.m {
            Preferences.shared.isWindowsMode = false
            NotificationCenter.default.post(name: .modeChanged, object: nil)
            return .some(nil)
        }
        return nil
    }

    private func showDesktop() {
        postKey(key: KeyCode.f11, flags: .maskSecondaryFn)
    }

    private func openFinder() {
        let finderURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.finder")!
        NSWorkspace.shared.openApplication(at: finderURL, configuration: NSWorkspace.OpenConfiguration()) { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.postKey(key: KeyCode.n, flags: .maskCommand)
            }
        }
    }
}

extension Notification.Name {
    static let modeChanged = Notification.Name("WinKeysModeChanged")
}
