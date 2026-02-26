import CoreGraphics

// Modifier flags for matching input events
struct ModMask: OptionSet, Hashable {
    let rawValue: UInt
    static let ctrl    = ModMask(rawValue: 1 << 0)
    static let alt     = ModMask(rawValue: 1 << 1)
    static let shift   = ModMask(rawValue: 1 << 2)
    static let cmd     = ModMask(rawValue: 1 << 3)  // Win key on Windows keyboards

    func isSubset(of other: ModMask) -> Bool {
        self.intersection(other) == self
    }
}

// Where a mapping applies
enum MappingScope {
    case global            // Applies everywhere
    case nonTerminal       // Applies except in terminal apps
    case finderOnly        // Applies only in Finder
}

struct KeyMapping {
    let inputKey: CGKeyCode
    let inputMods: ModMask
    let heldKeys: Set<CGKeyCode>   // 동시에 눌려있어야 하는 비수식키들
    let triggerOnRelease: Bool     // true면 키를 뗄 때 발동
    let outputKey: CGKeyCode
    let outputFlags: CGEventFlags
    let scope: MappingScope

    init(_ inputKey: CGKeyCode, _ inputMods: ModMask,
         _ outputKey: CGKeyCode, _ outputFlags: CGEventFlags,
         scope: MappingScope = .nonTerminal,
         heldKeys: Set<CGKeyCode> = [],
         triggerOnRelease: Bool = false) {
        self.inputKey = inputKey
        self.inputMods = inputMods
        self.heldKeys = heldKeys
        self.triggerOnRelease = triggerOnRelease
        self.outputKey = outputKey
        self.outputFlags = outputFlags
        self.scope = scope
    }
}

// Helper to build CGEventFlags
func flags(_ mods: CGEventFlags...) -> CGEventFlags {
    var result = CGEventFlags()
    for m in mods { result.insert(m) }
    return result
}

let cmdFlag = CGEventFlags.maskCommand
let shiftFlag = CGEventFlags.maskShift
let optFlag = CGEventFlags.maskAlternate
let ctrlFlag = CGEventFlags.maskControl
let noFlags = CGEventFlags()

// MARK: - All key mappings

let allMappings: [KeyMapping] = {
    var m: [KeyMapping] = []

    // --- Basic Ctrl → Cmd shortcuts (non-terminal) ---
    let ctrlToCmd: [CGKeyCode] = [
        KeyCode.c, KeyCode.v, KeyCode.x, KeyCode.z,
        KeyCode.a, KeyCode.s, KeyCode.f, KeyCode.n, KeyCode.o, KeyCode.p,
        KeyCode.t, KeyCode.w,
        KeyCode.r, KeyCode.l,
        KeyCode.b, KeyCode.i, KeyCode.u,
    ]
    for key in ctrlToCmd {
        m.append(KeyMapping(key, .ctrl, key, cmdFlag))
    }

    // Ctrl+Y → Cmd+Shift+Z (Redo)
    m.append(KeyMapping(KeyCode.y, .ctrl, KeyCode.z, flags(cmdFlag, shiftFlag)))

    // Ctrl+Shift+T → Cmd+Shift+T
    m.append(KeyMapping(KeyCode.t, [.ctrl, .shift], KeyCode.t, flags(cmdFlag, shiftFlag)))

    // Ctrl+H: 앱마다 동작이 달라 제거 (Chrome=방문기록, Pages=미지원 등)

    // F5 → Cmd+R (Refresh)
    m.append(KeyMapping(KeyCode.f5, [], KeyCode.r, cmdFlag))

    // --- System shortcuts (global) ---

    // Alt+Tab → Cmd+Tab (App switch)
    m.append(KeyMapping(KeyCode.tab, .alt, KeyCode.tab, cmdFlag, scope: .global))

    // Alt+F4 → Cmd+Q (Quit)
    m.append(KeyMapping(KeyCode.f4, .alt, KeyCode.q, cmdFlag, scope: .global))

    // Ctrl+Shift+Esc → Cmd+Option+Esc (Force Quit)
    m.append(KeyMapping(KeyCode.escape, [.ctrl, .shift], KeyCode.escape, flags(cmdFlag, optFlag), scope: .global))

    // Win+D → Show Desktop (직접 처리 in KeyRemapper)
    // Win+E → Open Finder (직접 처리 in KeyRemapper)
    // We map Win+E to a special action, not a key mapping

    // Win+L → Ctrl+Cmd+Q (Lock Screen)
    m.append(KeyMapping(KeyCode.l, .cmd, KeyCode.q, flags(ctrlFlag, cmdFlag), scope: .global))

    // Win+R → Cmd+Space (Spotlight)
    m.append(KeyMapping(KeyCode.r, .cmd, KeyCode.space, cmdFlag, scope: .global))

    // Win+Tab: macOS가 Cmd+Tab을 시스템 레벨에서 가로채므로 리매핑 불가

    // 스크린샷 (KeyRemapper에서 postKey로 직접 전송)
    // PrintScreen → Cmd+Shift+3 (전체 스크린샷)
    m.append(KeyMapping(KeyCode.f13, [], KeyCode.num3, flags(cmdFlag, shiftFlag), scope: .global))
    // Alt+PrintScreen → Cmd+Shift+4 + Space (창 캡처)
    m.append(KeyMapping(KeyCode.f13, .alt, KeyCode.num4, flags(cmdFlag, shiftFlag), scope: .global))
    // Shift+PrintScreen → Cmd+Shift+5 (스크린샷 도구)
    m.append(KeyMapping(KeyCode.f13, .shift, KeyCode.num5, flags(cmdFlag, shiftFlag), scope: .global))
    // Win+Shift+S → Cmd+Shift+4 (영역 지정)
    m.append(KeyMapping(KeyCode.s, [.cmd, .shift], KeyCode.num4, flags(cmdFlag, shiftFlag), scope: .global))

    // --- Navigation (non-terminal) ---

    // Home → Cmd+Left
    m.append(KeyMapping(KeyCode.home, [], KeyCode.leftArrow, cmdFlag))
    // End → Cmd+Right
    m.append(KeyMapping(KeyCode.end, [], KeyCode.rightArrow, cmdFlag))
    // Shift+Home → Cmd+Shift+Left (select to line start)
    m.append(KeyMapping(KeyCode.home, .shift, KeyCode.leftArrow, flags(cmdFlag, shiftFlag)))
    // Shift+End → Cmd+Shift+Right (select to line end)
    m.append(KeyMapping(KeyCode.end, .shift, KeyCode.rightArrow, flags(cmdFlag, shiftFlag)))

    // Ctrl+Home → Cmd+Up (document start)
    m.append(KeyMapping(KeyCode.home, .ctrl, KeyCode.upArrow, cmdFlag))
    // Ctrl+End → Cmd+Down (document end)
    m.append(KeyMapping(KeyCode.end, .ctrl, KeyCode.downArrow, cmdFlag))
    // Ctrl+Shift+Home → Cmd+Shift+Up (select to document start)
    m.append(KeyMapping(KeyCode.home, [.ctrl, .shift], KeyCode.upArrow, flags(cmdFlag, shiftFlag)))
    // Ctrl+Shift+End → Cmd+Shift+Down (select to document end)
    m.append(KeyMapping(KeyCode.end, [.ctrl, .shift], KeyCode.downArrow, flags(cmdFlag, shiftFlag)))

    // Ctrl+Left → Option+Left (word left)
    m.append(KeyMapping(KeyCode.leftArrow, .ctrl, KeyCode.leftArrow, optFlag))
    // Ctrl+Right → Option+Right (word right)
    m.append(KeyMapping(KeyCode.rightArrow, .ctrl, KeyCode.rightArrow, optFlag))
    // Ctrl+Shift+Left → Option+Shift+Left (select word left)
    m.append(KeyMapping(KeyCode.leftArrow, [.ctrl, .shift], KeyCode.leftArrow, flags(optFlag, shiftFlag)))
    // Ctrl+Shift+Right → Option+Shift+Right (select word right)
    m.append(KeyMapping(KeyCode.rightArrow, [.ctrl, .shift], KeyCode.rightArrow, flags(optFlag, shiftFlag)))

    // Ctrl+Backspace → Option+Backspace (delete word)
    m.append(KeyMapping(KeyCode.backspace, .ctrl, KeyCode.backspace, optFlag))

    // --- Finder-only mappings ---

    // F2 → Enter (Rename)
    m.append(KeyMapping(KeyCode.f2, [], KeyCode.returnKey, noFlags, scope: .finderOnly))

    // Enter → Cmd+O (Open)
    m.append(KeyMapping(KeyCode.returnKey, [], KeyCode.o, cmdFlag, scope: .finderOnly))

    // Delete → Cmd+Backspace (Trash)
    m.append(KeyMapping(KeyCode.delete, [], KeyCode.backspace, cmdFlag, scope: .finderOnly))

    // Backspace → Cmd+Up (Parent folder)
    m.append(KeyMapping(KeyCode.backspace, [], KeyCode.upArrow, cmdFlag, scope: .finderOnly))

    // Alt+Enter → Cmd+I (Get Info)
    m.append(KeyMapping(KeyCode.returnKey, .alt, KeyCode.i, cmdFlag, scope: .finderOnly))

    return m
}()
