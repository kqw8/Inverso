import CoreGraphics
import Foundation

public struct ScrollSample: Equatable {
    public var delta: Int64
    public var pointDelta: Double
    public var fixedPointDelta: Double

    public init(delta: Int64, pointDelta: Double, fixedPointDelta: Double) {
        self.delta = delta
        self.pointDelta = pointDelta
        self.fixedPointDelta = fixedPointDelta
    }

    public var hasValue: Bool {
        delta != 0 || pointDelta != 0.0 || fixedPointDelta != 0.0
    }

    public func usableValue(lineScale: Double) -> Double {
        if pointDelta != 0.0 { return pointDelta }
        if fixedPointDelta != 0.0 { return fixedPointDelta }
        return Double(delta) * lineScale
    }
}

public enum ScrollTransform {
    public static let syntheticMarker: Int64 = 0x00494E56524552534F
    public static let defaultLineScale = 12.0

    public static func verticalSample(from event: CGEvent) -> ScrollSample {
        ScrollSample(
            delta: event.getIntegerValueField(.scrollWheelEventDeltaAxis1),
            pointDelta: event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1),
            fixedPointDelta: event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        )
    }

    public static func horizontalSample(from event: CGEvent) -> ScrollSample {
        ScrollSample(
            delta: event.getIntegerValueField(.scrollWheelEventDeltaAxis2),
            pointDelta: event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2),
            fixedPointDelta: event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
        )
    }

    public static func verticalDelta(from event: CGEvent, lineScale: Double = defaultLineScale) -> Double {
        verticalSample(from: event).usableValue(lineScale: lineScale)
    }

    public static func hasHorizontalDelta(_ event: CGEvent) -> Bool {
        horizontalSample(from: event).hasValue
    }

    public static func isSynthetic(_ event: CGEvent) -> Bool {
        event.getIntegerValueField(.eventSourceUserData) == syntheticMarker
    }

    public static func markSynthetic(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: syntheticMarker)
    }

    public static func isLikelyTrackpad(_ event: CGEvent) -> Bool {
        event.getIntegerValueField(.scrollWheelEventScrollPhase) != 0
            || event.getIntegerValueField(.scrollWheelEventMomentumPhase) != 0
            || event.getIntegerValueField(.scrollWheelEventScrollCount) != 0
    }

    public static func clearVerticalFields(on event: CGEvent) {
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: 0)
        event.setDoubleValueField(.scrollWheelEventPointDeltaAxis1, value: 0.0)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: 0.0)
    }

    public static func reverseVerticalFields(on event: CGEvent) {
        let sample = verticalSample(from: event)
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: -sample.delta)
        event.setDoubleValueField(.scrollWheelEventPointDeltaAxis1, value: -sample.pointDelta)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: -sample.fixedPointDelta)
    }

    public static func setVerticalFields(on event: CGEvent, value: Double) {
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: Int64(value.rounded(.towardZero)))
        event.setDoubleValueField(.scrollWheelEventPointDeltaAxis1, value: value)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: value)
    }
}
