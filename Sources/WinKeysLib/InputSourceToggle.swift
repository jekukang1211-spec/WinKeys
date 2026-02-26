import Carbon

enum InputSourceToggle {
    static func toggle() {
        guard let sources = TISCreateInputSourceList(nil, false)?.takeRetainedValue() as? [TISInputSource] else {
            return
        }

        let selectableSources = sources.filter { source in
            guard let category = TISGetInputSourceProperty(source, kTISPropertyInputSourceCategory) else {
                return false
            }
            let cat = Unmanaged<CFString>.fromOpaque(category).takeUnretainedValue()
            guard cat == kTISCategoryKeyboardInputSource else { return false }

            guard let selectable = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsSelectCapable) else {
                return false
            }
            let sel = Unmanaged<CFBoolean>.fromOpaque(selectable).takeUnretainedValue()
            return CFBooleanGetValue(sel)
        }

        guard selectableSources.count >= 2 else { return }

        let current = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        guard let currentID = TISGetInputSourceProperty(current, kTISPropertyInputSourceID) else { return }
        let currentIDStr = Unmanaged<CFString>.fromOpaque(currentID).takeUnretainedValue() as String

        // Find next source (cycle through selectable sources)
        var foundCurrent = false
        var nextSource: TISInputSource?
        for source in selectableSources {
            guard let sid = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { continue }
            let sidStr = Unmanaged<CFString>.fromOpaque(sid).takeUnretainedValue() as String
            if foundCurrent {
                nextSource = source
                break
            }
            if sidStr == currentIDStr {
                foundCurrent = true
            }
        }
        // Wrap around to first
        if nextSource == nil {
            nextSource = selectableSources.first
        }

        if let next = nextSource {
            TISSelectInputSource(next)
        }
    }
}
