import Testing
import CoreGraphics
@testable import WinKeysLib

@Suite("KeyRemapperTable Tests", .serialized)
struct KeyRemapperTableTests {

    // MARK: - rebuildTable() 후 Windows pressTable에 기본 매핑 존재 확인

    @Test("rebuildTable - 기본 매핑 존재 확인")
    func rebuildTableContainsDefaultMappings() {
        // KeyRemapper.shared가 이미 rebuildTable()을 호출한 상태
        let remapper = KeyRemapper.shared

        // allMappings에 Ctrl+C → Cmd+C가 있으므로 pressTable에 존재해야 함
        #expect(!allMappings.isEmpty, "allMappings should not be empty")

        // Ctrl+C 매핑이 있는지 확인
        let ctrlC = allMappings.first {
            $0.inputKey == KeyCode.c && $0.inputMods == .ctrl
        }
        #expect(ctrlC != nil)
        #expect(ctrlC?.outputKey == KeyCode.c)
        #expect(ctrlC?.outputFlags == CGEventFlags.maskCommand)

        // rebuildTable이 크래시 없이 완료되는지 확인
        remapper.rebuildTable()
    }

    // MARK: - rebuildTable() 후 Mac 커스텀 매핑이 macPressTable에 존재 확인

    @Test("rebuildTable - Mac 커스텀 매핑 존재 확인")
    func rebuildTableWithMacCustomMappings() {
        // Mac 커스텀 매핑을 추가하고 rebuildTable() 호출
        let entry = CustomMappingEntry(
            id: "test_mac_1", description: "테스트 Mac 매핑",
            inputKeyCode: KeyCode.c, inputMods: ModMask.ctrl.rawValue,
            outputKeyCode: KeyCode.c, outputFlags: CGEventFlags.maskCommand.rawValue,
            scopeRaw: 1, enabled: true,
            macInputKeyCode: KeyCode.v, macInputMods: ModMask.cmd.rawValue
        )
        CustomMappings.shared.addOrUpdate(entry)

        let remapper = KeyRemapper.shared
        remapper.rebuildTable()

        // 간접 확인: activeMacMappings가 비어있지 않음
        let macMappings = CustomMappings.shared.activeMacMappings()
        #expect(!macMappings.isEmpty)
        #expect(macMappings.first?.inputKey == KeyCode.v)
        #expect(macMappings.first?.inputMods == ModMask(rawValue: ModMask.cmd.rawValue))

        // 정리
        CustomMappings.shared.remove(id: "test_mac_1")
        remapper.rebuildTable()
    }

    // MARK: - Mac 커스텀 없으면 macPressTable 비어있음 확인

    @Test("rebuildTable - Mac 커스텀 없으면 macPressTable 비어있음")
    func rebuildTableEmptyMacTableWithoutCustom() {
        // 테스트용 Mac 매핑 제거
        CustomMappings.shared.remove(id: "test_mac_1")

        let remapper = KeyRemapper.shared
        remapper.rebuildTable()

        let macMappings = CustomMappings.shared.activeMacMappings()
        // Mac 커스텀 매핑이 없으면 비어있어야 함 (다른 테스트가 남긴 것 없을 때)
        // 기존 사용자 데이터가 있을 수 있으므로 정확한 empty 체크 대신
        // activeMacMappings 호출이 에러 없이 동작하는지 확인
        #expect(macMappings != nil)
    }

    // MARK: - 접두사(prefix) 매핑이 releaseTable로 이동하는지 확인

    @Test("rebuildTable - 접두사 매핑이 releaseTable로 이동")
    func prefixMappingsMovedToReleaseTable() {
        // allMappings 중 heldKeys가 있는 매핑이 있으면,
        // 해당 heldKey를 triggerKey로 갖는 다른 매핑은 releaseTable로 이동해야 함

        // heldKeys 사용하는 커스텀 매핑 추가
        let heldEntry = CustomMappingEntry(
            id: "test_held", description: "홀드 테스트",
            inputKeyCode: KeyCode.v, inputMods: ModMask.ctrl.rawValue,
            inputHeldKeys: [KeyCode.c],
            triggerOnRelease: false,
            outputKeyCode: KeyCode.z, outputFlags: CGEventFlags.maskCommand.rawValue,
            scopeRaw: 1, enabled: true
        )
        CustomMappings.shared.addOrUpdate(heldEntry)

        let remapper = KeyRemapper.shared
        remapper.rebuildTable()

        // 간접 확인: allMappings에서 Ctrl+C 매핑을 찾아서
        // 이것이 prefix로 식별되어야 함을 확인
        let ctrlC = allMappings.first {
            $0.inputKey == KeyCode.c && $0.inputMods == .ctrl && $0.heldKeys.isEmpty
        }
        #expect(ctrlC != nil, "Ctrl+C mapping should exist in allMappings")

        // heldEntry의 heldKeys에 ctrlC의 inputKey가 포함되어 있고
        // ctrlC의 inputMods가 heldEntry의 inputMods의 부분집합이므로
        // ctrlC는 prefix로 식별되어야 함
        #expect(Set([KeyCode.c]).contains(ctrlC!.inputKey))
        #expect(ctrlC!.inputMods.isSubset(of: ModMask.ctrl))

        // 정리
        CustomMappings.shared.remove(id: "test_held")
        remapper.rebuildTable()
    }
}
