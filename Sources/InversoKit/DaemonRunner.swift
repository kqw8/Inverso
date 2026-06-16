import Foundation

public final class DaemonRunner {
    private let service = EventTapService()
    private var retryTimer: Timer?
    private var reportedMissingPermission = false

    public init() {}

    public func run() -> Never {
        startOrRetry()
        RunLoop.main.run()
        fatalError("run loop exited unexpectedly")
    }

    private func startOrRetry() {
        if !Accessibility.isTrusted {
            if !reportedMissingPermission {
                FileHandle.standardError.write(Data("inverso: Accessibility permission is missing; run `inverso permission` if you want macOS to show the prompt.\n".utf8))
                reportedMissingPermission = true
            }
            scheduleRetry()
            return
        }

        do {
            try service.start()
            reportedMissingPermission = false
            retryTimer?.invalidate()
            retryTimer = nil
        } catch {
            FileHandle.standardError.write(Data(("inverso: \(error)\n").utf8))
            scheduleRetry()
        }
    }

    private func scheduleRetry() {
        guard retryTimer == nil else { return }
        retryTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.startOrRetry()
        }
    }
}
