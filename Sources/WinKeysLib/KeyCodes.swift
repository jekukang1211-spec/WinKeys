import Carbon

// Carbon virtual key codes (kVK_*)
// Grouped for readability

enum KeyCode {
    // Letters
    static let a: CGKeyCode = CGKeyCode(kVK_ANSI_A)
    static let b: CGKeyCode = CGKeyCode(kVK_ANSI_B)
    static let c: CGKeyCode = CGKeyCode(kVK_ANSI_C)
    static let d: CGKeyCode = CGKeyCode(kVK_ANSI_D)
    static let e: CGKeyCode = CGKeyCode(kVK_ANSI_E)
    static let f: CGKeyCode = CGKeyCode(kVK_ANSI_F)
    static let h: CGKeyCode = CGKeyCode(kVK_ANSI_H)
    static let i: CGKeyCode = CGKeyCode(kVK_ANSI_I)
    static let l: CGKeyCode = CGKeyCode(kVK_ANSI_L)
    static let m: CGKeyCode = CGKeyCode(kVK_ANSI_M)
    static let n: CGKeyCode = CGKeyCode(kVK_ANSI_N)
    static let o: CGKeyCode = CGKeyCode(kVK_ANSI_O)
    static let p: CGKeyCode = CGKeyCode(kVK_ANSI_P)
    static let q: CGKeyCode = CGKeyCode(kVK_ANSI_Q)
    static let r: CGKeyCode = CGKeyCode(kVK_ANSI_R)
    static let s: CGKeyCode = CGKeyCode(kVK_ANSI_S)
    static let t: CGKeyCode = CGKeyCode(kVK_ANSI_T)
    static let u: CGKeyCode = CGKeyCode(kVK_ANSI_U)
    static let v: CGKeyCode = CGKeyCode(kVK_ANSI_V)
    static let w: CGKeyCode = CGKeyCode(kVK_ANSI_W)
    static let x: CGKeyCode = CGKeyCode(kVK_ANSI_X)
    static let y: CGKeyCode = CGKeyCode(kVK_ANSI_Y)
    static let z: CGKeyCode = CGKeyCode(kVK_ANSI_Z)

    // Numbers
    static let num0: CGKeyCode = CGKeyCode(kVK_ANSI_0)
    static let num1: CGKeyCode = CGKeyCode(kVK_ANSI_1)
    static let num2: CGKeyCode = CGKeyCode(kVK_ANSI_2)
    static let num3: CGKeyCode = CGKeyCode(kVK_ANSI_3)
    static let num4: CGKeyCode = CGKeyCode(kVK_ANSI_4)
    static let num5: CGKeyCode = CGKeyCode(kVK_ANSI_5)

    // Function keys
    static let f1: CGKeyCode = CGKeyCode(kVK_F1)
    static let f2: CGKeyCode = CGKeyCode(kVK_F2)
    static let f3: CGKeyCode = CGKeyCode(kVK_F3)
    static let f4: CGKeyCode = CGKeyCode(kVK_F4)
    static let f5: CGKeyCode = CGKeyCode(kVK_F5)
    static let f11: CGKeyCode = CGKeyCode(kVK_F11)
    static let f13: CGKeyCode = CGKeyCode(kVK_F13)

    // Navigation
    static let home: CGKeyCode = CGKeyCode(kVK_Home)
    static let end: CGKeyCode = CGKeyCode(kVK_End)
    static let leftArrow: CGKeyCode = CGKeyCode(kVK_LeftArrow)
    static let rightArrow: CGKeyCode = CGKeyCode(kVK_RightArrow)
    static let upArrow: CGKeyCode = CGKeyCode(kVK_UpArrow)
    static let downArrow: CGKeyCode = CGKeyCode(kVK_DownArrow)

    // Editing
    static let delete: CGKeyCode = CGKeyCode(kVK_ForwardDelete)
    static let backspace: CGKeyCode = CGKeyCode(kVK_Delete)
    static let returnKey: CGKeyCode = CGKeyCode(kVK_Return)
    static let tab: CGKeyCode = CGKeyCode(kVK_Tab)
    static let escape: CGKeyCode = CGKeyCode(kVK_Escape)
    static let space: CGKeyCode = CGKeyCode(kVK_Space)

    // Modifiers
    static let command: CGKeyCode = CGKeyCode(kVK_Command)
    static let rightCommand: CGKeyCode = CGKeyCode(kVK_RightCommand)
    static let option: CGKeyCode = CGKeyCode(kVK_Option)
    static let rightOption: CGKeyCode = CGKeyCode(kVK_RightOption)
    static let control: CGKeyCode = CGKeyCode(kVK_Control)
    static let rightControl: CGKeyCode = CGKeyCode(kVK_RightControl)
    static let shift: CGKeyCode = CGKeyCode(kVK_Shift)
    static let rightShift: CGKeyCode = CGKeyCode(kVK_RightShift)
    static let capsLock: CGKeyCode = CGKeyCode(kVK_CapsLock)

    // Special - PrintScreen doesn't exist on Mac keyboards but has this code
    // We use F13 as a proxy for PrintScreen if mapped
    // kVK_F13 = 0x69 (105)
}
