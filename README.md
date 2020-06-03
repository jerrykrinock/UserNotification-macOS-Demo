UserNotification-macOS-Demo
===========================

Demo of `UNUserNotificationCenter` in macOS.  I am posting this demo project because I found using `UNUserNotificationCenter` in my real apps was more difficult than it should have been, and also the Apple documentation does not define all of edge case behaviors.  Such edge cases can be tested with this demo.

`UNUserNotificationCenter` requires macOS 10.14 or later.  If you must support earlier versions, use `available(macOS 10.14`, and `NSUserNotificationCenter` in earlier systems.
