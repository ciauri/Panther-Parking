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
    
    static var notificationsEnabled: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(Constants.DefaultsKeys.notificationsEnabled)
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
            notificationsEnabled = false
        })
    }
    
    class func enableNotifications() {
        notificationsEnabled = true
        // Register for push notifications
        let application = UIApplication.sharedApplication()
        let notificationSettings = UIUserNotificationSettings(forTypes: .Alert, categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
        
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