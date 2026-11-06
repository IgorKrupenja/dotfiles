import AppKit
import UserNotifications

class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if let link = response.notification.request.content.userInfo["url"] as? String,
           let url = URL(string: link) {
            NSWorkspace.shared.open(url)
        }
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

    // Set before launch finishes, so a click that launched the app reaches the handler
    func applicationWillFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = handler
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let args      = CommandLine.arguments
        // No arguments: macOS launched the app for a click on a banner whose run had already quit
        guard args.count > 1 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { NSApp.terminate(nil) }
            return
        }
        let title     = args[1]
        let message   = args.count > 2 ? args[2] : ""
        let sound     = args.count > 3 ? args[3] : nil
        let bundleID  = args.count > 4 ? args[4] : "com.anthropic.claudefordesktop"
        let clickURL  = args.count > 5 ? args[5] : ""

        let appFrontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier?
            .lowercased().contains(bundleID.lowercased()) ?? false

        let center = UNUserNotificationCenter.current()

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
            content.userInfo = ["url": clickURL]
            if let name = sound, !appFrontmost {
                content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: name))
            }

            // One banner per click target: a session's new banner replaces its previous one
            let identifier = clickURL.isEmpty ? UUID().uuidString : clickURL
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
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
