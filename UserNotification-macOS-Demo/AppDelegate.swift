import Cocoa
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    
    @IBOutlet private weak var window: NSWindow!
    
    /* In documentation of UNUserNotificationCenterDelegate > Overview >
     Important, Apple states that "You must assign your delegate object to the
     UNUserNotificationCenter object before your app finishes launching".
     (They then go on to state that, in an iOS app, doing it in either
     application(_:willFinishLaunchingWithOptions:) or
     application(_:didFinishLaunchingWithOptions:) is OK.  As far as I know,
     the latter is not "before your app finishes launching".  So I be safe
     and do it in the former… */
    func applicationWillFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let unc = UNUserNotificationCenter.current()
        unc.requestAuthorization(options:[UNAuthorizationOptions.alert],
                                 completionHandler: { granted, error in
                                    print(String(format: "auth granted = %hhd", granted))
                                    if let error = error {
                                        print("auth error = \(error)")
                                    }
        })
        postNow(withTitle: "Demo app has launched")
    }
    
    @IBAction func notifyMe(_ sender: Any) {
        postNow(withTitle: "Button clicked")
    }
    
    func postNow(withTitle title: String!) {
        let content = UNMutableNotificationContent()
        content.subtitle = "You can put a Subtitle here"
        let uuidString = UUID.init().uuidString
        content.title = title
        content.body = "Posted at " + (Date().description)
        content.sound = UNNotificationSound.default
        let request = UNNotificationRequest(identifier: uuidString , content: content, trigger: nil)
        let unc = UNUserNotificationCenter.current()
        unc.add(request, withCompletionHandler: { error in
            if let error = error {
                print("error: \(error)")
            }
        })
    }
    
    /* The following implementation (from UNUserNotificationCenterDelegate) is
     necessary in order for the notification alert to display when we are the
     active application.  No thanks to Apple for hiding this fact way down in
     Local and Remote Notificaiton Programming Guide
     > Notifications in Your App > Scheduling and Handling Notifications >
     Handling Notifications When Your App Is in the Foreground. */
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("We must be the active app – handling delegate callback")
        completionHandler(UNNotificationPresentationOptions.alert)
    }
}

