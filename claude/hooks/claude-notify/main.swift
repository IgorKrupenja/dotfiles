import AppKit
import UserNotifications

class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    var clickURL: String = "vscode://"

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if let url = URL(string: clickURL) { NSWorkspace.shared.open(url) }
        completionHandler()
        NSApp.terminate(nil)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let handler = NotificationHandler()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let args      = CommandLine.arguments
        let title     = args.count > 1 ? args[1] : "Claude Code"
        let message   = args.count > 2 ? args[2] : ""
        let sound     = args.count > 3 ? args[3] : nil
        let bundleID  = args.count > 4 ? args[4] : "com.microsoft.vscode"
        handler.clickURL = args.count > 5 ? args[5] : "vscode://"

        let ideFrontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier?
            .lowercased().contains(bundleID.lowercased()) ?? false

        let center = UNUserNotificationCenter.current()
        center.delegate = handler

        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error { fputs("Auth error: \(error)\n", stderr) }
            guard granted else {
                fputs("Notifications not authorized\n", stderr)
                DispatchQueue.main.async { NSApp.terminate(nil) }
                return
            }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body  = message
            if let name = sound, !ideFrontmost {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: name))
            }

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request) { error in
                if let error { fputs("Error: \(error)\n", stderr) }
                // Time out after 5 min if user doesn't click
                DispatchQueue.main.asyncAfter(deadline: .now() + 300) {
                    NSApp.terminate(nil)
                }
            }
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let delegate = AppDelegate()
app.delegate = delegate
app.run()
