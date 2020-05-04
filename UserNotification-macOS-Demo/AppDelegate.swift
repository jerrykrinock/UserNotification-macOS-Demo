import Cocoa
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func dateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter;
    }
    
    @IBOutlet private weak var window: NSWindow!
    @IBOutlet private var titleField: NSTextField!
    @IBOutlet private var subtitleField: NSTextField!
    @IBOutlet private var bodyField: NSTextField!
    @IBOutlet private var soundCheckbox: NSButton!

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
        unc.requestAuthorization(options:[UNAuthorizationOptions.alert,
                                          UNAuthorizationOptions.sound],
                                 completionHandler: { granted, error in
                                    print(String(format: "auth granted = %hhd", granted))
                                    if let error = error {
                                        print("auth error = \(error)")
                                    }
        })
    }
    
    @IBAction func addNotification(_sender:NSButton) {
        let content = UNMutableNotificationContent()
        content.title = titleField.stringValue
        content.subtitle = subtitleField.stringValue
        if (bodyField.stringValue.lengthOfBytes(using:String.Encoding.utf8) > 0) {
            let dateString = self.dateFormatter().string(from: Date())
            content.body = bodyField.stringValue + " [" + (dateString + "]")
        }
        let uuidString = UUID.init().uuidString
        
        if (soundCheckbox.state == NSControl.StateValue.on) {
            /* See Apple documentation UserNotifications > UNNotificationSound
             for requirements and search paths applied to custom sound files. */
            let soundName = UNNotificationSoundName.init("MyCustomDemoAlertSound")
            /* In the Objective-C equivalent, soundName is simply a NSString. */
            let sound = UNNotificationSound.init(named:soundName)
            content.sound = sound
            
            /* Using the system's default sound instead would be simply */
            // content.sound = UNNotificationSound.default
        }
        
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

