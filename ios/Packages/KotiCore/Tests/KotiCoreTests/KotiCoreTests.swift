import XCTest
@testable import KotiCore

final class KotiCoreTests: XCTestCase {
    func testKotiModeTargets() {
        XCTAssertEqual(KotiMode.trial.targetCount, 108)
        XCTAssertEqual(KotiMode.lakh.targetCount, 100_000)
        XCTAssertEqual(KotiMode.crore.targetCount, 10_000_000)
    }

    func testStylusEngineParsesHexColor() {
        let engine = StylusEngine(colorHex: "#E34234")
        let (r, g, b, a) = engine.rgbaComponents()
        XCTAssertEqual(r, 0xE3 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(g, 0x42 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(b, 0x34 / 255.0, accuracy: 0.0001)
        XCTAssertEqual(a, 1.0, accuracy: 0.0001)
    }

    func testCadenceValidatorFlagsTooFastEntries() {
        let validator = CadenceValidator()
        let intervals: [TimeInterval] = [0.05, 0.5, 0.6, 0.4, 0.55]
        XCTAssertEqual(validator.flaggedIndices(intervals: intervals), [0])
    }

    func testCadenceSignatureIsDeterministic() {
        let validator = CadenceValidator()
        let intervals: [TimeInterval] = [0.5, 0.6, 0.55, 0.7]
        let a = validator.cadenceSignature(intervals: intervals, salt: "abc")
        let b = validator.cadenceSignature(intervals: intervals, salt: "abc")
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.count, 64) // SHA256 hex
    }
}
