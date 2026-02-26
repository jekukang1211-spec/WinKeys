import CoreGraphics
import Foundation

final class EventTapManager {
    static let shared = EventTapManager()

    fileprivate var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    func start() -> Bool {
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: nil
        ) else {
            NSLog("WinKeys: Failed to create event tap. Accessibility permission required.")
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        NSLog("WinKeys: Event tap started successfully")
        return true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        NSLog("WinKeys: Event tap stopped")
    }

    var isRunning: Bool {
        eventTap != nil
    }
}

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    // If tap is disabled by the system, re-enable it
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if let tap = EventTapManager.shared.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    let remapper = KeyRemapper.shared

    if type == .flagsChanged {
        if let result = remapper.processFlagsChanged(event) {
            return Unmanaged.passUnretained(result)
        }
        return nil // Suppress
    }

    if type == .keyDown || type == .keyUp {
        if let result = remapper.processKeyEvent(event, type: type) {
            return Unmanaged.passUnretained(result)
        }
        return nil // Suppress
    }

    return Unmanaged.passUnretained(event)
}

