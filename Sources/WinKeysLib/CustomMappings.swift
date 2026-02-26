import Foundation
import CoreGraphics

// 사용자 커스텀 매핑 저장/로드
// 기본 매핑을 오버라이드하거나 새 매핑을 추가할 수 있음

struct CustomMappingEntry: Codable {
    let id: String           // 고유 ID (예: "ctrl_c", "alt_f4", "custom_1")
    let description: String  // 설명 (예: "복사", "앱 종료")
    let inputKeyCode: UInt16
    let inputMods: UInt      // ModMask rawValue
    let inputHeldKeys: [UInt16]  // 동시에 눌려있어야 하는 비수식키 코드들
    let triggerOnRelease: Bool   // true면 키를 뗄 때 발동
    let outputKeyCode: UInt16
    let outputFlags: UInt64  // CGEventFlags rawValue
    let scopeRaw: Int        // 0=global, 1=nonTerminal, 2=finderOnly
    let enabled: Bool
    let macInputKeyCode: UInt16?  // nil = 기본값 (= 출력과 동일, 패스스루)
    let macInputMods: UInt?       // nil = 기본값

    // 기존 데이터 호환을 위한 디코더
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        description = try c.decode(String.self, forKey: .description)
        inputKeyCode = try c.decode(UInt16.self, forKey: .inputKeyCode)
        inputMods = try c.decode(UInt.self, forKey: .inputMods)
        inputHeldKeys = try c.decodeIfPresent([UInt16].self, forKey: .inputHeldKeys) ?? []
        triggerOnRelease = try c.decodeIfPresent(Bool.self, forKey: .triggerOnRelease) ?? false
        outputKeyCode = try c.decode(UInt16.self, forKey: .outputKeyCode)
        outputFlags = try c.decode(UInt64.self, forKey: .outputFlags)
        scopeRaw = try c.decode(Int.self, forKey: .scopeRaw)
        enabled = try c.decode(Bool.self, forKey: .enabled)
        macInputKeyCode = try c.decodeIfPresent(UInt16.self, forKey: .macInputKeyCode)
        macInputMods = try c.decodeIfPresent(UInt.self, forKey: .macInputMods)
    }

    init(id: String, description: String, inputKeyCode: UInt16, inputMods: UInt,
         inputHeldKeys: [UInt16] = [], triggerOnRelease: Bool = false,
         outputKeyCode: UInt16, outputFlags: UInt64, scopeRaw: Int, enabled: Bool,
         macInputKeyCode: UInt16? = nil, macInputMods: UInt? = nil) {
        self.id = id
        self.description = description
        self.inputKeyCode = inputKeyCode
        self.inputMods = inputMods
        self.inputHeldKeys = inputHeldKeys
        self.triggerOnRelease = triggerOnRelease
        self.outputKeyCode = outputKeyCode
        self.outputFlags = outputFlags
        self.scopeRaw = scopeRaw
        self.enabled = enabled
        self.macInputKeyCode = macInputKeyCode
        self.macInputMods = macInputMods
    }

    var scope: MappingScope {
        switch scopeRaw {
        case 0: return .global
        case 2: return .finderOnly
        default: return .nonTerminal
        }
    }

    func toKeyMapping() -> KeyMapping {
        KeyMapping(
            CGKeyCode(inputKeyCode),
            ModMask(rawValue: inputMods),
            CGKeyCode(outputKeyCode),
            CGEventFlags(rawValue: outputFlags),
            scope: scope,
            heldKeys: Set(inputHeldKeys.map { CGKeyCode($0) }),
            triggerOnRelease: triggerOnRelease
        )
    }

    /// Mac 모드용 매핑 생성: macInput → 동일 output
    /// macInputKeyCode가 nil이면 nil 반환 (패스스루 = 커스텀 없음)
    func toMacKeyMapping() -> KeyMapping? {
        guard let macKey = macInputKeyCode, let macMods = macInputMods else { return nil }
        return KeyMapping(
            CGKeyCode(macKey),
            ModMask(rawValue: macMods),
            CGKeyCode(outputKeyCode),
            CGEventFlags(rawValue: outputFlags),
            scope: scope,
            heldKeys: [],
            triggerOnRelease: false
        )
    }
}

final class CustomMappings {
    static let shared = CustomMappings()

    private let key = "customMappings"
    private var entries: [CustomMappingEntry] = []

    init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([CustomMappingEntry].self, from: data) else {
            entries = []
            return
        }
        entries = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func allEntries() -> [CustomMappingEntry] {
        entries
    }

    func activeMappings() -> [KeyMapping] {
        entries.filter { $0.enabled }.map { $0.toKeyMapping() }
    }

    func activeMacMappings() -> [KeyMapping] {
        entries.filter { $0.enabled }.compactMap { $0.toMacKeyMapping() }
    }

    func addOrUpdate(_ entry: CustomMappingEntry) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[idx] = entry
        } else {
            entries.append(entry)
        }
        save()
    }

    func remove(id: String) {
        entries.removeAll { $0.id == id }
        save()
    }

    func findConflict(inputKeyCode: UInt16, inputMods: UInt, inputHeldKeys: [UInt16] = [], excludeId: String?) -> String? {
        let heldSet = Set(inputHeldKeys)
        // 커스텀 매핑에서 충돌 검사
        for entry in entries {
            if entry.id != excludeId && entry.inputKeyCode == inputKeyCode
                && entry.inputMods == inputMods && Set(entry.inputHeldKeys) == heldSet {
                return entry.description
            }
        }
        // 기본 매핑에서 충돌 검사
        let modMask = ModMask(rawValue: inputMods)
        for mapping in allMappings {
            if mapping.inputKey == CGKeyCode(inputKeyCode) && mapping.inputMods == modMask
                && mapping.heldKeys == Set(inputHeldKeys.map { CGKeyCode($0) }) {
                return keyMappingDescription(mapping)
            }
        }
        return nil
    }

    // macOS 기본 단축키 충돌 검사
    func findMacOSConflict(keyCode: UInt16, mods: UInt) -> String? {
        let modMask = ModMask(rawValue: mods)
        for (k, m, name) in Self.macOSShortcuts {
            if k == CGKeyCode(keyCode) && m == modMask {
                return name
            }
        }
        return nil
    }

    /// Mac 입력 충돌 검사: 다른 커스텀 Mac 입력 + allMappings 기본 Mac 입력(=출력)과 비교
    func findMacConflict(keyCode: UInt16, mods: UInt, excludeId: String?) -> String? {
        let checkKey = CGKeyCode(keyCode)
        let checkMods = ModMask(rawValue: mods)

        // 1. 다른 커스텀 엔트리의 macInput과 비교
        for entry in entries {
            if entry.id == excludeId { continue }
            guard entry.enabled else { continue }
            if let macKey = entry.macInputKeyCode, let macMods = entry.macInputMods {
                if CGKeyCode(macKey) == checkKey && ModMask(rawValue: macMods) == checkMods {
                    return entry.description
                }
            }
        }

        // 2. allMappings의 출력(= 기본 Mac 입력)과 비교
        for mapping in allMappings {
            let defaultMacKey = mapping.outputKey
            let defaultMacMods = eventFlagsToModMask(mapping.outputFlags)

            if defaultMacKey == checkKey && defaultMacMods == checkMods {
                // 단, 해당 매핑에 이미 커스텀 Mac 입력이 설정되어 있으면 기본값은 가려져 있으므로 건너뜀
                let entryId = "custom_\(mapping.inputKey)_\(mapping.inputMods.rawValue)"
                if entryId == excludeId { continue }
                let existingEntry = entries.first(where: { $0.id == entryId && $0.enabled })
                if existingEntry?.macInputKeyCode != nil {
                    continue  // 커스텀 Mac 입력이 있으면 기본값은 사용 안 함
                }
                return keyMappingDescription(mapping)
            }
        }

        return nil
    }

    /// CGEventFlags → ModMask 변환
    func eventFlagsToModMask(_ flags: CGEventFlags) -> ModMask {
        var mask = ModMask()
        if flags.contains(.maskControl) { mask.insert(.ctrl) }
        if flags.contains(.maskAlternate) { mask.insert(.alt) }
        if flags.contains(.maskShift) { mask.insert(.shift) }
        if flags.contains(.maskCommand) { mask.insert(.cmd) }
        return mask
    }

    private static var macOSShortcuts: [(CGKeyCode, ModMask, String)] { [
        // 기본 편집
        (KeyCode.c, .cmd, L("action.copy")),
        (KeyCode.v, .cmd, L("action.paste")),
        (KeyCode.x, .cmd, L("action.cut")),
        (KeyCode.z, .cmd, L("action.undo")),
        (KeyCode.a, .cmd, L("action.selectAll")),
        (KeyCode.s, .cmd, L("action.save")),
        // 앱 제어
        (KeyCode.q, .cmd, L("action.appQuit")),
        (KeyCode.w, .cmd, L("macos.closeWindow")),
        (KeyCode.h, .cmd, L("macos.hideApp")),
        (KeyCode.m, .cmd, L("macos.minimize")),
        (KeyCode.n, .cmd, L("macos.newWindow")),
        // 시스템
        (KeyCode.tab, .cmd, L("action.appSwitch")),
        (KeyCode.space, .cmd, L("action.spotlight")),
        // 찾기/열기
        (KeyCode.f, .cmd, L("action.find")),
        (KeyCode.o, .cmd, L("action.open")),
        (KeyCode.p, .cmd, L("action.print")),
        // 탭/문서
        (KeyCode.t, .cmd, L("action.newTab")),
        (KeyCode.l, .cmd, L("macos.addressBarGo")),
        (KeyCode.r, .cmd, L("action.refresh")),
        // Shift 조합
        (KeyCode.z, [.cmd, .shift], L("action.redo")),
        (KeyCode.s, [.cmd, .shift], L("macos.saveAs")),
        (KeyCode.num3, [.cmd, .shift], L("action.screenshotFull")),
        (KeyCode.num4, [.cmd, .shift], L("macos.areaScreenshot")),
        (KeyCode.num5, [.cmd, .shift], L("action.screenshotTool")),
        // Option 조합
        (KeyCode.escape, [.cmd, .alt], L("action.forceQuit")),
        (KeyCode.h, [.cmd, .alt], L("macos.hideOtherApps")),
        // Control 조합
        (KeyCode.q, [.ctrl, .cmd], L("action.lockScreen")),
        (KeyCode.space, .ctrl, L("macos.inputSourceToggle")),
        // Fn / 기타
        (KeyCode.f, [.cmd, .ctrl], L("macos.fullScreen")),
        (KeyCode.backspace, .cmd, L("macos.moveToTrash")),
        (KeyCode.delete, .cmd, L("macos.moveToTrash")),
        (KeyCode.i, .cmd, L("macos.getInfo")),
        (KeyCode.d, .cmd, L("macos.duplicate")),
        (KeyCode.e, .cmd, L("macos.export")),
        (KeyCode.b, .cmd, L("action.bold")),
        (KeyCode.i, .cmd, L("action.italic")),
        (KeyCode.u, .cmd, L("action.underline")),
    ] }

    private func keyMappingDescription(_ mapping: KeyMapping) -> String {
        // 기본 매핑의 설명을 키코드로 추정
        let descriptions: [CGKeyCode: [ModMask: String]] = [
            KeyCode.c: [.ctrl: L("action.copy")],
            KeyCode.v: [.ctrl: L("action.paste")],
            KeyCode.x: [.ctrl: L("action.cut")],
            KeyCode.z: [.ctrl: L("action.undo")],
            KeyCode.a: [.ctrl: L("action.selectAll")],
            KeyCode.s: [.ctrl: L("action.save")],
            KeyCode.f: [.ctrl: L("action.find")],
            KeyCode.t: [.ctrl: L("action.newTab")],
            KeyCode.w: [.ctrl: L("action.closeTab")],
            KeyCode.tab: [.alt: L("action.appSwitch")],
        ]
        if let modDesc = descriptions[mapping.inputKey], let desc = modDesc[mapping.inputMods] {
            return desc
        }
        return L("macos.existingShortcut")
    }
}

// 키코드를 읽기 쉬운 이름으로 변환
func keyCodeName(_ keyCode: CGKeyCode) -> String {
    let names: [CGKeyCode: String] = [
        KeyCode.a: "A", KeyCode.b: "B", KeyCode.c: "C", KeyCode.d: "D",
        KeyCode.e: "E", KeyCode.f: "F", KeyCode.h: "H", KeyCode.i: "I",
        KeyCode.l: "L", KeyCode.m: "M", KeyCode.n: "N", KeyCode.o: "O",
        KeyCode.p: "P", KeyCode.q: "Q", KeyCode.r: "R", KeyCode.s: "S",
        KeyCode.t: "T", KeyCode.u: "U", KeyCode.v: "V", KeyCode.w: "W",
        KeyCode.x: "X", KeyCode.y: "Y", KeyCode.z: "Z",
        KeyCode.num0: "0", KeyCode.num1: "1", KeyCode.num2: "2",
        KeyCode.num3: "3", KeyCode.num4: "4", KeyCode.num5: "5",
        KeyCode.f1: "F1", KeyCode.f2: "F2", KeyCode.f3: "F3",
        KeyCode.f4: "F4", KeyCode.f5: "F5", KeyCode.f11: "F11", KeyCode.f13: "PrintScreen",
        KeyCode.home: "Home", KeyCode.end: "End",
        KeyCode.leftArrow: "←", KeyCode.rightArrow: "→",
        KeyCode.upArrow: "↑", KeyCode.downArrow: "↓",
        KeyCode.delete: "Delete", KeyCode.backspace: "Backspace",
        KeyCode.returnKey: "Enter", KeyCode.tab: "Tab",
        KeyCode.escape: "Esc", KeyCode.space: "Space",
        // 수식키
        KeyCode.command: "Left Cmd", KeyCode.rightCommand: "Right Cmd",
        KeyCode.option: "Left Alt", KeyCode.rightOption: "Right Alt",
        KeyCode.control: "Left Ctrl", KeyCode.rightControl: "Right Ctrl",
        KeyCode.shift: "Left Shift", KeyCode.rightShift: "Right Shift",
        KeyCode.capsLock: "CapsLock",
    ]
    return names[keyCode] ?? "Key(\(keyCode))"
}

func modMaskName(_ mods: ModMask) -> String {
    var parts: [String] = []
    if mods.contains(.ctrl) { parts.append("Ctrl") }
    if mods.contains(.alt) { parts.append("Alt") }
    if mods.contains(.shift) { parts.append("Shift") }
    if mods.contains(.cmd) { parts.append("Win") }
    return parts.joined(separator: "+")
}

func shortcutName(keyCode: CGKeyCode, mods: ModMask, heldKeys: Set<CGKeyCode> = []) -> String {
    var parts: [String] = []
    let modStr = modMaskName(mods)
    if !modStr.isEmpty { parts.append(modStr) }
    for hk in heldKeys.sorted() { parts.append(keyCodeName(hk)) }
    parts.append(keyCodeName(keyCode))
    return parts.joined(separator: "+")
}

// Mac 스타일 수식키 이름 (출력 컬럼용)
func macModName(_ flags: CGEventFlags) -> String {
    var parts: [String] = []
    if flags.contains(.maskControl) { parts.append("Control") }
    if flags.contains(.maskAlternate) { parts.append("Option") }
    if flags.contains(.maskShift) { parts.append("Shift") }
    if flags.contains(.maskCommand) { parts.append("Cmd") }
    return parts.joined(separator: "+")
}

func macShortcutName(keyCode: CGKeyCode, flags: CGEventFlags) -> String {
    let modStr = macModName(flags)
    let keyStr = keyCodeName(keyCode)
    if modStr.isEmpty { return keyStr }
    return "\(modStr)+\(keyStr)"
}
