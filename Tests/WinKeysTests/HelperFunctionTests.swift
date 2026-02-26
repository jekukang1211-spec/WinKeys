import Testing
import CoreGraphics
@testable import WinKeysLib

@Suite("HelperFunction Tests")
struct HelperFunctionTests {

    // MARK: - keyCodeName(): 알려진 키 이름 반환

    @Test("keyCodeName - 알려진 키 이름 반환")
    func keyCodeNameKnownKeys() {
        #expect(keyCodeName(KeyCode.a) == "A")
        #expect(keyCodeName(KeyCode.z) == "Z")
        #expect(keyCodeName(KeyCode.num0) == "0")
        #expect(keyCodeName(KeyCode.f1) == "F1")
        #expect(keyCodeName(KeyCode.home) == "Home")
        #expect(keyCodeName(KeyCode.escape) == "Esc")
        #expect(keyCodeName(KeyCode.space) == "Space")
        #expect(keyCodeName(KeyCode.tab) == "Tab")
        #expect(keyCodeName(KeyCode.returnKey) == "Enter")
        #expect(keyCodeName(KeyCode.leftArrow) == "←")
    }

    @Test("keyCodeName - 알 수 없는 키 코드")
    func keyCodeNameUnknownKey() {
        let unknown = keyCodeName(CGKeyCode(999))
        #expect(unknown == "Key(999)")
    }

    // MARK: - modMaskName(): 수식키 조합 이름

    @Test("modMaskName - 단일 수식키")
    func modMaskNameSingle() {
        #expect(modMaskName(.ctrl) == "Ctrl")
        #expect(modMaskName(.alt) == "Alt")
        #expect(modMaskName(.shift) == "Shift")
        #expect(modMaskName(.cmd) == "Win")
    }

    @Test("modMaskName - 수식키 조합")
    func modMaskNameCombination() {
        let ctrlAlt: ModMask = [.ctrl, .alt]
        #expect(modMaskName(ctrlAlt) == "Ctrl+Alt")

        let ctrlShift: ModMask = [.ctrl, .shift]
        #expect(modMaskName(ctrlShift) == "Ctrl+Shift")

        let all: ModMask = [.ctrl, .alt, .shift, .cmd]
        #expect(modMaskName(all) == "Ctrl+Alt+Shift+Win")
    }

    @Test("modMaskName - 빈 수식키")
    func modMaskNameEmpty() {
        #expect(modMaskName(ModMask()) == "")
    }

    // MARK: - shortcutName(): 전체 단축키 문자열

    @Test("shortcutName - 기본 단축키 문자열")
    func shortcutName_basic() {
        let name = shortcutName(keyCode: KeyCode.c, mods: .ctrl)
        #expect(name == "Ctrl+C")
    }

    @Test("shortcutName - 수식키 없는 단축키")
    func shortcutNameNoMods() {
        let name = shortcutName(keyCode: KeyCode.f5, mods: ModMask())
        #expect(name == "F5")
    }

    @Test("shortcutName - heldKeys 포함 단축키")
    func shortcutNameWithHeldKeys() {
        let name = shortcutName(keyCode: KeyCode.c, mods: .ctrl, heldKeys: Set([KeyCode.v]))
        #expect(name.contains("Ctrl"))
        #expect(name.contains("C"))
        #expect(name.contains("V"))
    }

    // MARK: - macModName(): Mac 스타일 수식키 이름

    @Test("macModName - 단일 Mac 수식키")
    func macModName_basic() {
        #expect(macModName(CGEventFlags.maskCommand) == "Cmd")
        #expect(macModName(CGEventFlags.maskAlternate) == "Option")
        #expect(macModName(CGEventFlags.maskControl) == "Control")
        #expect(macModName(CGEventFlags.maskShift) == "Shift")
    }

    @Test("macModName - Mac 수식키 조합")
    func macModNameCombination() {
        let flags = CGEventFlags([.maskCommand, .maskShift])
        #expect(macModName(flags) == "Shift+Cmd")
    }

    // MARK: - macShortcutName(): Mac 스타일 전체 이름

    @Test("macShortcutName - Mac 스타일 단축키")
    func macShortcutName_basic() {
        let name = macShortcutName(keyCode: KeyCode.c, flags: .maskCommand)
        #expect(name == "Cmd+C")
    }

    @Test("macShortcutName - 플래그 없는 Mac 단축키")
    func macShortcutNameNoFlags() {
        let name = macShortcutName(keyCode: KeyCode.f5, flags: CGEventFlags())
        #expect(name == "F5")
    }

    // MARK: - eventFlagsToModMask(): CGEventFlags → ModMask 변환

    @Test("eventFlagsToModMask - CGEventFlags → ModMask 변환")
    func eventFlagsToModMask() {
        let cm = CustomMappings()

        let mask1 = cm.eventFlagsToModMask(.maskControl)
        #expect(mask1 == .ctrl)

        let mask2 = cm.eventFlagsToModMask(.maskAlternate)
        #expect(mask2 == .alt)

        let mask3 = cm.eventFlagsToModMask(.maskShift)
        #expect(mask3 == .shift)

        let mask4 = cm.eventFlagsToModMask(.maskCommand)
        #expect(mask4 == .cmd)

        let combined = cm.eventFlagsToModMask(CGEventFlags([.maskControl, .maskCommand]))
        #expect(combined == [.ctrl, .cmd])
    }

    @Test("eventFlagsToModMask - 빈 플래그")
    func eventFlagsToModMaskEmpty() {
        let cm = CustomMappings()
        let mask = cm.eventFlagsToModMask(CGEventFlags())
        #expect(mask == ModMask())
    }

    // MARK: - ModMask.isSubset(of:): 부분집합 테스트

    @Test("ModMask.isSubset(of:) - 부분집합 테스트")
    func modMaskIsSubset() {
        let ctrl: ModMask = .ctrl
        let ctrlAlt: ModMask = [.ctrl, .alt]

        #expect(ctrl.isSubset(of: ctrlAlt))
        #expect(!ctrlAlt.isSubset(of: ctrl))
        #expect(ctrl.isSubset(of: ctrl))
        #expect(ModMask().isSubset(of: ctrl))
    }
}
