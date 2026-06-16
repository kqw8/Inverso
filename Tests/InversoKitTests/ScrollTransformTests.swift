import CoreGraphics
import InversoKit
import XCTest

final class ScrollTransformTests: XCTestCase {
    func testVerticalDeltaPrefersPointDelta() throws {
        let event = try makeEvent(delta: 2, point: 7.0, fixed: 3.0)
        XCTAssertEqual(ScrollTransform.verticalDelta(from: event), 7.0)
    }

    func testVerticalDeltaFallsBackToFixedPoint() throws {
        let event = try makeEvent(delta: 2, point: 0.0, fixed: 3.5)
        XCTAssertEqual(ScrollTransform.verticalDelta(from: event), 3.5)
    }

    func testVerticalDeltaFallsBackToLineScaledDelta() throws {
        let event = try makeEvent(delta: 2, point: 0.0, fixed: 0.0)
        XCTAssertEqual(ScrollTransform.verticalDelta(from: event, lineScale: 12.0), 24.0)
    }

    func testSetVerticalFieldsWritesAllVerticalFields() throws {
        let event = try makeEvent()
        ScrollTransform.setVerticalFields(on: event, value: -5.5)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), -5)
        XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1), -5.0)
        XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1), -5.5)
    }

    func testReverseVerticalFieldsNegatesOnlyVerticalFields() throws {
        let event = try makeEvent(delta: 4, point: 8.0, fixed: 2.0, horizontalDelta: 3, horizontalPoint: 6.0)
        ScrollTransform.reverseVerticalFields(on: event)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), -4)
        XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1), -8.0)
        XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1), -2.0)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis2), 3)
        XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2), 6.0)
    }

    func testClearVerticalFieldsDoesNotClearHorizontalFields() throws {
        let event = try makeEvent(delta: 4, point: 8.0, fixed: 2.0, horizontalDelta: 3, horizontalPoint: 6.0)
        ScrollTransform.clearVerticalFields(on: event)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis1), 0)
        XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1), 0.0)
        XCTAssertEqual(event.getIntegerValueField(.scrollWheelEventDeltaAxis2), 3)
        XCTAssertEqual(event.getDoubleValueField(.scrollWheelEventPointDeltaAxis2), 6.0)
    }

    func testSyntheticMarkerRoundTrips() throws {
        let event = try makeEvent()
        XCTAssertFalse(ScrollTransform.isSynthetic(event))
        ScrollTransform.markSynthetic(event)
        XCTAssertTrue(ScrollTransform.isSynthetic(event))
    }

    func testTrackpadHeuristicUsesPhasesAndScrollCount() throws {
        let event = try makeEvent()
        XCTAssertFalse(ScrollTransform.isLikelyTrackpad(event))
        event.setIntegerValueField(.scrollWheelEventScrollPhase, value: 2)
        XCTAssertTrue(ScrollTransform.isLikelyTrackpad(event))
    }

    private func makeEvent(
        delta: Int64 = 0,
        point: Double = 0.0,
        fixed: Double = 0.0,
        horizontalDelta: Int64 = 0,
        horizontalPoint: Double = 0.0
    ) throws -> CGEvent {
        guard let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: 0, wheel2: 0, wheel3: 0) else {
            throw NSError(domain: "InversoTests", code: 1)
        }
        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: delta)
        event.setDoubleValueField(.scrollWheelEventPointDeltaAxis1, value: point)
        event.setDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1, value: fixed)
        event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: horizontalDelta)
        event.setDoubleValueField(.scrollWheelEventPointDeltaAxis2, value: horizontalPoint)
        return event
    }
}
