import Testing
import Foundation
import CoreGraphics
@testable import WinKeysLib

@Suite("CustomMappingEntry Tests")
struct CustomMappingEntryTests {

    // MARK: - JSON 디코딩 역호환 (macInputKeyCode 없는 기존 데이터)

    @Test("JSON 디코딩 - macInputKeyCode 없는 기존 데이터 역호환")
    func decodeWithoutMacInputKeyCode() throws {
        let json = """
        {
            "id": "ctrl_c",
            "description": "복사",
            "inputKeyCode": 8,
            "inputMods": 1,
            "outputKeyCode": 8,
            "outputFlags": 1048840,
            "scopeRaw": 1,
            "enabled": true
        }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(CustomMappingEntry.self, from: json)
        #expect(entry.id == "ctrl_c")
        #expect(entry.description == "복사")
        #expect(entry.inputKeyCode == 8)
        #expect(entry.inputMods == 1)
        #expect(entry.inputHeldKeys == [])
        #expect(entry.triggerOnRelease == false)
        #expect(entry.macInputKeyCode == nil)
        #expect(entry.macInputMods == nil)
    }

    // MARK: - JSON 디코딩 (macInputKeyCode 있는 데이터)

    @Test("JSON 디코딩 - macInputKeyCode 포함 데이터")
    func decodeWithMacInputKeyCode() throws {
        let json = """
        {
            "id": "custom_1",
            "description": "커스텀 매핑",
            "inputKeyCode": 8,
            "inputMods": 1,
            "inputHeldKeys": [9],
            "triggerOnRelease": true,
            "outputKeyCode": 8,
            "outputFlags": 1048840,
            "scopeRaw": 0,
            "enabled": true,
            "macInputKeyCode": 12,
            "macInputMods": 8
        }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(CustomMappingEntry.self, from: json)
        #expect(entry.id == "custom_1")
        #expect(entry.inputHeldKeys == [9])
        #expect(entry.triggerOnRelease == true)
        #expect(entry.macInputKeyCode == 12)
        #expect(entry.macInputMods == 8)
    }

    // MARK: - toKeyMapping() 변환 정확성

    @Test("toKeyMapping() 변환 정확성")
    func toKeyMapping() {
        let entry = CustomMappingEntry(
            id: "test",
            description: "테스트",
            inputKeyCode: 8,
            inputMods: 1,   // .ctrl
            inputHeldKeys: [9],
            triggerOnRelease: false,
            outputKeyCode: 8,
            outputFlags: CGEventFlags.maskCommand.rawValue,
            scopeRaw: 1,    // nonTerminal
            enabled: true
        )

        let mapping = entry.toKeyMapping()
        #expect(mapping.inputKey == CGKeyCode(8))
        #expect(mapping.inputMods == ModMask(rawValue: 1))
        #expect(mapping.outputKey == CGKeyCode(8))
        #expect(mapping.outputFlags == CGEventFlags.maskCommand)
        #expect(mapping.heldKeys == Set([CGKeyCode(9)]))
        #expect(mapping.triggerOnRelease == false)
    }

    // MARK: - toMacKeyMapping() — nil일 때 nil 반환

    @Test("toMacKeyMapping() - nil일 때 nil 반환")
    func toMacKeyMappingReturnsNilWhenNoMacInput() {
        let entry = CustomMappingEntry(
            id: "test",
            description: "테스트",
            inputKeyCode: 8,
            inputMods: 1,
            outputKeyCode: 8,
            outputFlags: CGEventFlags.maskCommand.rawValue,
            scopeRaw: 1,
            enabled: true,
            macInputKeyCode: nil,
            macInputMods: nil
        )

        #expect(entry.toMacKeyMapping() == nil)
    }

    // MARK: - toMacKeyMapping() — 값 있을 때 정확한 KeyMapping 생성

    @Test("toMacKeyMapping() - 값 있을 때 정확한 KeyMapping 생성")
    func toMacKeyMappingReturnsMapping() {
        let entry = CustomMappingEntry(
            id: "test",
            description: "테스트",
            inputKeyCode: 8,
            inputMods: 1,
            outputKeyCode: 8,
            outputFlags: CGEventFlags.maskCommand.rawValue,
            scopeRaw: 0,   // global
            enabled: true,
            macInputKeyCode: 12,
            macInputMods: 8  // .cmd
        )

        let mapping = entry.toMacKeyMapping()
        #expect(mapping != nil)
        #expect(mapping!.inputKey == CGKeyCode(12))
        #expect(mapping!.inputMods == ModMask(rawValue: 8))
        #expect(mapping!.outputKey == CGKeyCode(8))
        #expect(mapping!.outputFlags == CGEventFlags.maskCommand)
        #expect(mapping!.heldKeys.isEmpty)
        #expect(mapping!.triggerOnRelease == false)
    }

    // MARK: - scope 변환

    @Test("scope 변환 정확성")
    func scopeConversion() {
        let global = CustomMappingEntry(
            id: "g", description: "", inputKeyCode: 0, inputMods: 0,
            outputKeyCode: 0, outputFlags: 0, scopeRaw: 0, enabled: true
        )
        #expect(global.scope == .global)

        let nonTerminal = CustomMappingEntry(
            id: "n", description: "", inputKeyCode: 0, inputMods: 0,
            outputKeyCode: 0, outputFlags: 0, scopeRaw: 1, enabled: true
        )
        #expect(nonTerminal.scope == .nonTerminal)

        let finderOnly = CustomMappingEntry(
            id: "f", description: "", inputKeyCode: 0, inputMods: 0,
            outputKeyCode: 0, outputFlags: 0, scopeRaw: 2, enabled: true
        )
        #expect(finderOnly.scope == .finderOnly)
    }
}
