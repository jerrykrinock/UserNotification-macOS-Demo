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
    @IBOutlet private var actionsTextField: NSTextField!
    @IBOutlet private var olderThanTextField: NSTextField!

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
    
    @IBAction func visitSystemPreferences(_sender: NSButton) {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications")
        if let url = url {
            NSWorkspace.shared.open(url)
        }
    }
    
    @IBAction func removeStaleDeliveredNotificationsOlderThan(_sender: NSButton) {
        let unc = UNUserNotificationCenter.current()
        unc.getDeliveredNotifications(completionHandler: { notifications in
            print("Found \(notifications.count) delivered notifications still in Notification Center")
            var doomedNotificationIdentifiers : [String] = []
            /* We are likely on a secondary thread here must switch to main
             to read a value from user interface. */
            var olderThanSeconds: Double = 0.0
            DispatchQueue.main.sync {
                olderThanSeconds = 60 * Double(self.olderThanTextField.integerValue)
            }
            
            for aNotification in notifications {
                if (aNotification.date < Date().addingTimeInterval(-olderThanSeconds)) {
                    doomedNotificationIdentifiers.append(aNotification.request.identifier)
                }
            }
            print("Removing \(doomedNotificationIdentifiers.count) stale delivered notifications.")
            unc.removeDeliveredNotifications(withIdentifiers: doomedNotificationIdentifiers)
        })
    }

    @IBAction func addNotification(_sender:NSButton) {
        let content = UNMutableNotificationContent()
        content.title = titleField.stringValue
        content.subtitle = subtitleField.stringValue
        let dateString = self.dateFormatter().string(from: Date())
        if (bodyField.stringValue.lengthOfBytes(using:String.Encoding.utf8) > 0) {
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
        
        content.categoryIdentifier = "MY_CATEGORY";
        content.userInfo = [
            "MY_TIMESTAMP" : dateString
        ]
        
        var actions = Array<UNNotificationAction>()
        if (actionsTextField.integerValue > 0) {
            for index in 1...actionsTextField.integerValue {
                let identifier = "ACTION_\(index)"
                let title = "Action \(index)"
                let action = UNNotificationAction(identifier: identifier,
                                                  title: title,
                                                  options: UNNotificationActionOptions(rawValue: 0))
                actions.append(action)
            }
        }
        
        let unc = UNUserNotificationCenter.current()

        /* This section is not necessary on the first run if number of actions
         is 0, because categories are empty by default.  But setting the
         categories to an empty array is necessary if the number of actions
         is being reduced from nonzero to zero, because Notification Center
         remembers your categories from the prior run of this app.
         
         Also, the .customDismissAction is necessary if you want
         .userNotificationCenter(_:didReceive:withCompletionHandler:) to be
         called, sending you the UNNotificationDismissActionIdentifier
         action, when your user clicks the 'Close' button in a banner or alert,
         or clicks in the non-button area of an alert.
         */
        let myCategory = UNNotificationCategory(identifier: "MY_CATEGORY",
                                                actions: actions,
                                                intentIdentifiers: [],  // these would be for Siri
                                                hiddenPreviewsBodyPlaceholder: "",
                                                options: .customDismissAction)
        unc.setNotificationCategories([myCategory])
        
        let request = UNNotificationRequest(identifier: uuidString , content: content, trigger: nil)
        unc.add(request, withCompletionHandler: { error in
            if let error = error {
                print("error: \(error)")
            }
        })
    }
    
    /* The following implementation (from UNUserNotificationCenterDelegate) is
     necessary in order for the notification alert to display when we are the
     active application.  No thanks to Apple for hiding this fact way down in
     Local and Remote Notification Programming Guide
     > Notifications in Your App > Scheduling and Handling Notifications >
     Handling Notifications When Your App Is in the Foreground. */
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("We must be the active app – handling delegate callback")
        completionHandler(UNNotificationPresentationOptions.alert)
    }
    
    /* This method must be implememnted or the buttons will not show on
     your alert.  That is, it will be a banner instead of an alert.  If
     you are only showing banners, you do not need this method. */
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler:
        @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        let timestamp = userInfo["MY_TIMESTAMP"] as! String
        
        // Perform the task associated with the action.
        let actionIdentifier = response.actionIdentifier
        if (actionIdentifier == UNNotificationDefaultActionIdentifier) {
            print("Received DEFAULT action for notification added at \(timestamp).  This happens when your user clicks in the body of a banner or alert, which causes the banner or alert to be dismissed, without clicking any of its buttons.  Note: User can click either on the banner, while it is visible on the desktop, or on the notification *in* Notification Center.")
        } else if (actionIdentifier == UNNotificationDismissActionIdentifier) {
            print("Received DISMISS action for notification added at \(timestamp).  This happens When your user clicks the 'Close' button in a banner or alert, or clicks in the non-button area of an alert.")
        } else {
            print("Received action \(actionIdentifier as String) for notification added at \(timestamp)")
        }
        
        // Always call the completion handler when done.
        completionHandler()
    }
}
