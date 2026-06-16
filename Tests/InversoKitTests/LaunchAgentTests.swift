import InversoKit
import XCTest

final class LaunchAgentTests: XCTestCase {
    func testPlistContainsEssentials() {
        let plist = LaunchAgent.plistContents(executablePath: "/usr/local/bin/inverso")
        XCTAssertTrue(plist.contains("<string>com.kqw8.inverso</string>"))
        XCTAssertTrue(plist.contains("<string>/usr/local/bin/inverso</string>"))
        XCTAssertTrue(plist.contains("<string>--daemon</string>"))
        XCTAssertTrue(plist.contains("<key>RunAtLoad</key>"))
        XCTAssertTrue(plist.contains("<key>KeepAlive</key>"))
    }

    func testParsesDisabledStateVariants() {
        let booleanOutput = #""com.kqw8.inverso" => true"#
        let wordOutput = #""com.kqw8.inverso" => enabled"#
        XCTAssertEqual(LaunchAgent.disabledState(for: "com.kqw8.inverso", in: booleanOutput), true)
        XCTAssertEqual(LaunchAgent.disabledState(for: "com.kqw8.inverso", in: wordOutput), false)
    }
}
