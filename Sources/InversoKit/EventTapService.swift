import ApplicationServices
import CoreGraphics
import Foundation

public final class EventTapService {
    public enum ServiceError: Error, CustomStringConvertible {
        case accessibilityPermissionMissing
        case eventTapCreationFailed
        case runLoopSourceCreationFailed

        public var description: String {
            switch self {
            case .accessibilityPermissionMissing:
                return "accessibility permission is missing"
            case .eventTapCreationFailed:
                return "could not create the scroll event tap"
            case .runLoopSourceCreationFailed:
                return "could not create the event tap run loop source"
            }
        }
    }

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    public init() {}

    public func start() throws {
        guard Accessibility.isTrusted else {
            throw ServiceError.accessibilityPermissionMissing
        }
        if eventTap != nil { return }

        let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgAnnotatedSessionEventTap,
            place: .tailAppendEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: Self.handleEvent,
            userInfo: context
        ) else {
            throw ServiceError.eventTapCreationFailed
        }
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            throw ServiceError.runLoopSourceCreationFailed
        }

        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource, CFRunLoopContainsSource(CFRunLoopGetMain(), source, .commonModes) {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        runLoopSource = nil
        eventTap = nil
    }

    deinit {
        stop()
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            reenableSoon()
            return Unmanaged.passUnretained(event)
        }
        guard type == .scrollWheel else {
            return Unmanaged.passUnretained(event)
        }
        if ScrollTransform.isSynthetic(event) || ScrollTransform.isLikelyTrackpad(event) {
            return Unmanaged.passUnretained(event)
        }

        let vertical = ScrollTransform.verticalSample(from: event)
        guard vertical.hasValue else {
            return Unmanaged.passUnretained(event)
        }

        ScrollTransform.reverseVerticalFields(on: event)
        return Unmanaged.passUnretained(event)
    }

    private func reenableSoon() {
        guard let eventTap else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }

    private static let handleEvent: CGEventTapCallBack = { _, type, event, refcon in
        guard let refcon else {
            return Unmanaged.passUnretained(event)
        }
        let service = Unmanaged<EventTapService>.fromOpaque(refcon).takeUnretainedValue()
        return service.handle(type: type, event: event)
    }
}
