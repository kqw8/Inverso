import Foundation

public enum LaunchAgent {
    public static let label = "com.kqw8.inverso"

    public static var plistURL: URL {
        URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    private static var domainTarget: String { "gui/\(getuid())" }
    private static var serviceTarget: String { "gui/\(getuid())/\(label)" }

    public static func logPaths() -> [String] {
        let dir = NSHomeDirectory() + "/Library/Logs"
        return ["\(dir)/inverso.out.log", "\(dir)/inverso.err.log"]
    }

    public static func plistContents(executablePath: String) -> String {
        let logs = logPaths()
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(label)</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(executablePath)</string>
                <string>--daemon</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>ProcessType</key>
            <string>Background</string>
            <key>StandardOutPath</key>
            <string>\(logs[0])</string>
            <key>StandardErrorPath</key>
            <string>\(logs[1])</string>
        </dict>
        </plist>
        """
    }

    @discardableResult
    public static func writePlist(executablePath: String) throws -> URL {
        let url = plistURL
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try plistContents(executablePath: executablePath).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @discardableResult
    public static func removePlist() -> Bool {
        do {
            if plistExists() {
                try FileManager.default.removeItem(at: plistURL)
            }
            return !plistExists()
        } catch {
            return false
        }
    }

    public static func plistExists() -> Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    @discardableResult
    public static func bootstrap() -> Bool {
        if isBootstrapped() { return true }
        _ = launchctl(["bootstrap", domainTarget, plistURL.path])
        return isBootstrapped()
    }

    @discardableResult
    public static func bootout() -> Bool {
        if !isBootstrapped() { return true }
        _ = launchctl(["bootout", serviceTarget])
        return !isBootstrapped()
    }

    @discardableResult
    public static func kickstart() -> Bool {
        let result = launchctl(["kickstart", "-k", serviceTarget])
        return result.status == 0 && isBootstrapped()
    }

    @discardableResult
    public static func enableLogin() -> Bool {
        launchctl(["enable", serviceTarget]).status == 0 && isLoginEnabled()
    }

    @discardableResult
    public static func disableLogin() -> Bool {
        launchctl(["disable", serviceTarget]).status == 0 && !isLoginEnabled()
    }

    public static func isBootstrapped() -> Bool {
        launchctl(["print", serviceTarget]).status == 0
    }

    public static func isLoginEnabled() -> Bool {
        guard plistExists() else { return false }
        let output = launchctl(["print-disabled", domainTarget]).output
        if let isDisabled = disabledState(for: label, in: output) {
            return !isDisabled
        }
        return true
    }

    public static func disabledState(for label: String, in output: String) -> Bool? {
        for line in output.split(separator: "\n") where line.contains("\"\(label)\"") {
            let lower = line.lowercased()
            if lower.contains("=> true") || lower.contains("=> disabled") { return true }
            if lower.contains("=> false") || lower.contains("=> enabled") { return false }
        }
        return nil
    }

    @discardableResult
    private static func launchctl(_ args: [String]) -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
        } catch {
            return (-1, "failed to run launchctl: \(error)")
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(data: data, encoding: .utf8) ?? "")
    }
}
