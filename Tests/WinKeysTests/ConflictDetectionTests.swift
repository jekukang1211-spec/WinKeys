import Testing
import CoreGraphics
import Carbon.HIToolbox
@testable import WinKeysLib

@Suite("ConflictDetection Tests", .serialized)
struct ConflictDetectionTests {

    private let cm: CustomMappings

    init() {
        cm = CustomMappings()
        // 테스트 시작 시 기존 엔트리 모두 제거 (빈 상태에서 시작)
        for entry in cm.allEntries() {
            cm.remove(id: entry.id)
        }
    }

    // MARK: - findConflict(): Win-Win 중복 차단

    @Test("findConflict - Win-Win 중복 차단")
    func findConflictDetectsWinWinDuplicate() {
        let entry1 = CustomMappingEntry(
            id: "e1", description: "매핑1",
            inputKeyCode: KeyCode.c, inputMods: ModMask.ctrl.rawValue,
            outputKeyCode: KeyCode.c, outputFlags: CGEventFlags.maskCommand.rawValue,
            scopeRaw: 1, enabled: true
        )
        cm.addOrUpdate(entry1)

        // 같은 입력으로 충돌 검사
        let conflict = cm.findConflict(
            inputKeyCode: KeyCode.c, inputMods: ModMask.ctrl.rawValue, excludeId: nil
        )
        #expect(conflict != nil)
        #expect(conflict == "매핑1")
    }

    // MARK: - findConflict(): excludeId로 자기 자신 제외

    @Test("findConflict - excludeId로 자기 자신 제외")
    func findConflictExcludesSelf() {
        let entry = CustomMappingEntry(
            id: "e1", description: "매핑1",
            inputKeyCode: KeyCode.c, inputMods: ModMask.ctrl.rawValue,
            outputKeyCode: KeyCode.c, outputFlags: CGEventFlags.maskCommand.rawValue,
            scopeRaw: 1, enabled: true
        )
        cm.addOrUpdate(entry)

        // 자기 자신 제외하면 충돌 없을 수 있음 (기본 매핑과의 충돌은 있을 수 있음)
        let conflict = cm.findConflict(
            inputKeyCode: KeyCode.c, inputMods: ModMask.ctrl.rawValue, excludeId: "e1"
        )
        // allMappings에 Ctrl+C → Cmd+C가 있으므로 기본 매핑과 충돌
        #expect(conflict != nil)
    }

    // MARK: - findConflict(): allMappings 기본 매핑과 충돌 감지

    @Test("findConflict - allMappings 기본 매핑과 충돌 감지")
    func findConflictDetectsDefaultMappingConflict() {
        // allMappings에 Ctrl+C → Cmd+C가 있음
        let conflict = cm.findConflict(
            inputKeyCode: KeyCode.c, inputMods: ModMask.ctrl.rawValue, excludeId: nil
        )
        #expect(conflict != nil)
        // "복사"라는 설명이어야 함
        #expect(conflict == "복사")
    }

    // MARK: - findMacConflict(): Mac-Mac 커스텀 중복 차단

    @Test("findMacConflict - Mac-Mac 커스텀 중복 차단")
    func findMacConflictDetectsMacMacDuplicate() {
        let entry1 = CustomMappingEntry(
            id: "e1", description: "매핑1",
            inputKeyCode: KeyCode.c, inputMods: ModMask.ctrl.rawValue,
            outputKeyCode: KeyCode.c, outputFlags: CGEventFlags.maskCommand.rawValue,
            scopeRaw: 1, enabled: true,
            macInputKeyCode: KeyCode.v, macInputMods: ModMask.cmd.rawValue
        )
        cm.addOrUpdate(entry1)

        // 다른 커스텀이 같은 mac 입력을 쓰려 할 때
        let conflict = cm.findMacConflict(
            keyCode: KeyCode.v, mods: ModMask.cmd.rawValue, excludeId: "e2"
        )
        #expect(conflict != nil)
        #expect(conflict == "매핑1")
    }

    // MARK: - findMacConflict(): Mac커스텀 vs Mac기본(allMappings 출력) 충돌 감지

    @Test("findMacConflict - Mac기본 출력과 충돌 감지")
    func findMacConflictDetectsDefaultOutputConflict() {
        // allMappings에 Ctrl+C → Cmd+C 매핑이 있음
        // 즉 기본 Mac 입력 = Cmd+C
        // 커스텀 Mac 입력으로 Cmd+C를 쓰려 하면 충돌
        let conflict = cm.findMacConflict(
            keyCode: KeyCode.c, mods: ModMask.cmd.rawValue, excludeId: nil
        )
        // allMappings에서 output이 Cmd+C인 매핑이 있으므로 충돌
        #expect(conflict != nil)
    }

    // MARK: - findMacConflict(): 기본값이 커스텀으로 가려진 경우 건너뜀

    @Test("findMacConflict - 기본값이 커스텀으로 가려진 경우 건너뜀")
    func findMacConflictSkipsOverriddenDefaults() {
        // allMappings에 Ctrl+C → Cmd+C가 있음 (출력 = Cmd+C)
        // 해당 매핑에 대응하는 커스텀 엔트리에 macInputKeyCode가 설정되어 있으면
        // 기본 Mac 입력(Cmd+C)은 가려져서 충돌로 간주하지 않아야 함

        // 먼저 Ctrl+C 매핑에 대응하는 커스텀 엔트리 ID를 구성
        let ctrlC = allMappings.first { $0.inputKey == KeyCode.c && $0.inputMods == .ctrl }!
        let entryId = "custom_\(ctrlC.inputKey)_\(ctrlC.inputMods.rawValue)"

        // 해당 ID로 macInputKeyCode가 설정된 커스텀 엔트리 추가
        let overrideEntry = CustomMappingEntry(
            id: entryId, description: "커스텀 복사",
            inputKeyCode: KeyCode.c, inputMods: ModMask.ctrl.rawValue,
            outputKeyCode: KeyCode.c, outputFlags: CGEventFlags.maskCommand.rawValue,
            scopeRaw: 1, enabled: true,
            macInputKeyCode: KeyCode.x, macInputMods: ModMask.cmd.rawValue  // 다른 키로 오버라이드
        )
        cm.addOrUpdate(overrideEntry)

        // 이제 Cmd+C를 Mac 입력으로 쓰려 하면, 기본값이 가려져 있으므로 충돌 없어야 함
        let conflict = cm.findMacConflict(
            keyCode: KeyCode.c, mods: ModMask.cmd.rawValue, excludeId: nil
        )
        #expect(conflict == nil)
    }

    // MARK: - findMacOSConflict(): macOS 시스템 단축키 감지

    @Test("findMacOSConflict - macOS 시스템 단축키 감지")
    func findMacOSConflictDetectsSystemShortcut() {
        // Cmd+C는 macOS 시스템 단축키 "복사"
        let conflict = cm.findMacOSConflict(keyCode: KeyCode.c, mods: ModMask.cmd.rawValue)
        #expect(conflict != nil)
        #expect(conflict == "복사")
    }

    // MARK: - findMacOSConflict(): 목록에 없는 단축키는 nil

    @Test("findMacOSConflict - 목록에 없는 단축키는 nil")
    func findMacOSConflictReturnsNilForUnknown() {
        // Cmd+G는 시스템 단축키 목록에 없음
        let conflict = cm.findMacOSConflict(
            keyCode: CGKeyCode(kVK_ANSI_G), mods: ModMask.cmd.rawValue
        )
        #expect(conflict == nil)
    }
}
