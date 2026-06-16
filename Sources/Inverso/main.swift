import Darwin
import Foundation
import InversoKit

let inversoVersion = "0.1.0"

func currentExecutablePath() -> String {
    var size: UInt32 = 0
    _NSGetExecutablePath(nil, &size)
    var buffer = [CChar](repeating: 0, count: Int(size))
    if _NSGetExecutablePath(&buffer, &size) == 0 {
        return URL(fileURLWithPath: String(cString: buffer)).resolvingSymlinksInPath().path
    }
    return CommandLine.arguments.first ?? "inverso"
}

func printErr(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

func usage() {
    print("""
    inverso \(inversoVersion)

    Usage:
      inverso install      Install and start the background service, enabled at login
      inverso uninstall    Stop the service and remove LaunchAgent/logs
      inverso start        Start the background service
      inverso stop         Stop the background service
      inverso status       Show service and permission state
      inverso permission   Ask macOS for Accessibility permission
      inverso --daemon     Run the background event tap
    """)
}

func install() {
    let exe = currentExecutablePath()
    if LaunchAgent.isBootstrapped(), !LaunchAgent.bootout() {
        printErr("❌ Install failed: could not unload the existing background service.")
        exit(1)
    }
    do {
        try LaunchAgent.writePlist(executablePath: exe)
    } catch {
        printErr("❌ Install failed: could not write LaunchAgent plist: \(error)")
        exit(1)
    }
    guard LaunchAgent.enableLogin(), LaunchAgent.bootstrap(), LaunchAgent.kickstart(), LaunchAgent.isBootstrapped() else {
        printErr("❌ Install failed: the background service did not load.")
        exit(1)
    }
    print("✅ Inverso installed and running.")
    print("   • Start at login: on")
    print("   • Accessibility:  \(Accessibility.isTrusted ? "granted" : "needs approval in System Settings")")
}

func uninstall() {
    _ = LaunchAgent.bootout()
    _ = LaunchAgent.disableLogin()
    guard LaunchAgent.removePlist() else {
        printErr("❌ Uninstall failed: could not remove LaunchAgent plist.")
        exit(1)
    }
    for path in LaunchAgent.logPaths() {
        try? FileManager.default.removeItem(atPath: path)
    }
    print("✅ Inverso stopped and removed its LaunchAgent/logs.")
    print("   Binary still lives at: \(currentExecutablePath())")
}

func start() {
    if !LaunchAgent.plistExists() {
        do {
            try LaunchAgent.writePlist(executablePath: currentExecutablePath())
        } catch {
            printErr("❌ Start failed: could not write LaunchAgent plist: \(error)")
            exit(1)
        }
    }
    guard LaunchAgent.enableLogin(), LaunchAgent.bootstrap(), LaunchAgent.kickstart(), LaunchAgent.isBootstrapped() else {
        printErr("❌ Start failed: the background service did not load.")
        exit(1)
    }
    print("✅ Inverso background service started.")
}

func stop() {
    guard LaunchAgent.bootout() else {
        printErr("❌ Stop failed: the background service is still loaded.")
        exit(1)
    }
    print("✅ Inverso background service stopped.")
}

func status() {
    print("inverso \(inversoVersion) — status")
    print("")
    print("Input permission:")
    print("  • Accessibility:     \(Accessibility.isTrusted ? "granted" : "missing")")
    print("")
    print("Residency / autostart:")
    print("  • Background service: \(LaunchAgent.isBootstrapped() ? "running" : "not running")")
    print("  • Start at login:     \(LaunchAgent.isLoginEnabled() ? "on" : "off")")
    print("")
    print("LaunchAgent:")
    print("  • \(LaunchAgent.plistURL.path)")
}

func requestPermission() {
    if Accessibility.isTrusted {
        print("✅ Accessibility permission granted.")
        return
    }

    _ = Accessibility.requestPrompt()
    print("⏳ Waiting for Accessibility approval for:")
    print("   \(currentExecutablePath())")
    print("   Keep this command running while approving Inverso in System Settings.")

    let deadline = Date().addingTimeInterval(120)
    var nextReminder = Date().addingTimeInterval(15)
    while Date() < deadline {
        if Accessibility.isTrusted {
            print("✅ Accessibility permission granted.")
            return
        }
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        if Date() >= nextReminder {
            print("   Still waiting...")
            nextReminder = Date().addingTimeInterval(15)
        }
    }

    printErr("⚠️  Accessibility permission is still missing.")
    printErr("   If Inverso is not listed, add this binary manually:")
    printErr("   \(currentExecutablePath())")
    exit(1)
}

let args = Array(CommandLine.arguments.dropFirst())
switch args.first {
case "--daemon":
    DaemonRunner().run()
case "install":
    install()
case "uninstall":
    uninstall()
case "start":
    start()
case "stop":
    stop()
case "status":
    status()
case "permission":
    requestPermission()
case "--version", "-v":
    print("inverso \(inversoVersion)")
case nil, "help", "--help", "-h":
    usage()
default:
    usage()
    exit(2)
}
