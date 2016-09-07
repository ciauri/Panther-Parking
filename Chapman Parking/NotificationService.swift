//
//  NotificationService.swift
//  PantherPark
//
//  Created by Stephen Ciauri on 9/3/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation
import UIKit

class NotificationService {
    static var api: ParkingAPI?
    
    /// Validates both the iOS notification status and the in-app user preference. If user preference is true, but notifications are disabled in iOS, then the app will unregister for all notifications
    static var notificationsEnabled: Bool {
        get {
            if NSUserDefaults.standardUserDefaults().boolForKey(Constants.DefaultsKeys.notificationsEnabled) {
                if let types = UIApplication.sharedApplication().currentUserNotificationSettings()?.types where types != .None {
                    return true
                } else {
                    disableNotifications()
                    return false
                }
            } else {
                return false
            }
        } set{
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: Constants.DefaultsKeys.notificationsEnabled)
        }
    }
    
    static var structuresOnly: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(Constants.DefaultsKeys.structuresOnly)
        } set{
            NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: Constants.DefaultsKeys.structuresOnly)
        }
    }
    
    class func disableNotifications() {
        notificationsEnabled = false
        api?.unsubscribeFromAll({
            NSLog("Unsubbed")
            DataManager.sharedInstance.disableAllNotifications()
        })
    }
    
    class func enableNotifications(sender: UIViewController) {
        notificationsEnabled = true
        // Register for push notifications
        let application = UIApplication.sharedApplication()
        let notificationSettings = UIUserNotificationSettings(forTypes: .Alert, categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
        
        if let types = application.currentUserNotificationSettings()?.types where types == .None {
            notificationsEnabled = false
            promptForNotificationSettings(onViewController: sender)
        }
    }
    
    private class func promptForNotificationSettings(onViewController viewController: UIViewController) {
        let alertController = UIAlertController(title: "Notification Error",
                                                message: "It appears that you have disallowed push notifications. Please enable them in your device settings if you wish to receive them.",
                                                preferredStyle: .Alert)
        let settingsAction = UIAlertAction(title: "Settings",
                                        style: .Cancel,
                                        handler: {_ in
                                            UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
        })
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .Destructive,
                                         handler: nil)
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        
        viewController.presentViewController(alertController,
                                             animated: true,
                                             completion: nil)
    }

    class func disableNotificationFor(level: Level) {
        api?.unsubscribeFrom(ParkingEntity.Level,
                             withUUID: level.uuid!,
                             predicate: NSPredicate(format: "CurrentCount = %d",0),
                             onActions: RemoteAction.Update,
                             completion: { success in
                                if success {
                                   DataManager.sharedInstance.update(notificationsEnabled: false, forLevel: level)
                                }

        })
    }
    
    class func enableNotificationFor(level: Level) {
        guard let structureName = level.structure?.name, levelName = level.name else {return}
        api?.subscribeTo(ParkingEntity.Level,
                         withUUID: level.uuid!,
                         predicate: NSPredicate(format: "CurrentCount = %d",0),
                         onActions: RemoteAction.Update,
                         notificationText: "\(structureName) \(levelName) is now full",
                         completion: { success in
                            if success {
                                DataManager.sharedInstance.update(notificationsEnabled: true, forLevel: level)
                            }
        })

    }
}