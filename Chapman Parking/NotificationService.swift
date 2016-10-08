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
    static let sharedInstance = NotificationService()
    
    var api: ParkingAPI?
    
    /// Validates both the iOS notification status and the in-app user preference. If user preference is true, but notifications are disabled in iOS, then the app will unregister for all notifications
    var notificationsEnabled: Bool {
        get {
            if UserDefaults.standard.bool(forKey: Constants.DefaultsKeys.notificationsEnabled) {
                if let types = UIApplication.shared.currentUserNotificationSettings?.types , types != UIUserNotificationType() {
                    return true
                } else {
                    disableNotifications()
                    return false
                }
            } else {
                return false
            }
        } set{
            UserDefaults.standard.set(newValue, forKey: Constants.DefaultsKeys.notificationsEnabled)
        }
    }
    
    var structuresOnly: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Constants.DefaultsKeys.structuresOnly)
        } set{
            UserDefaults.standard.set(newValue, forKey: Constants.DefaultsKeys.structuresOnly)
        }
    }
    
    fileprivate init() {
        NotificationCenter.default.addObserver(self, selector: #selector(checkNotificationsEnabled), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    func disableNotifications() {
        notificationsEnabled = false
        api?.unsubscribeFromAll({
            NSLog("Unsubbed")
            DataManager.sharedInstance.disableAllNotifications()
        })
    }
    
    func fetchNotificationUUIDs(_ completion: @escaping (_ uuids: [String]) -> ()) {
        api?.fetchSubscriptions(completion)
    }
    
    func enableNotifications(_ sender: UIViewController? = nil, success: (()->())? = nil, failure: (()->())? = nil) {
        notificationsEnabled = true
        // Register for push notifications
        let application = UIApplication.shared
        let notificationSettings = UIUserNotificationSettings(types: .alert, categories: nil)
        application.registerUserNotificationSettings(notificationSettings)
        application.registerForRemoteNotifications()
        
        if let sender = sender, let types = application.currentUserNotificationSettings?.types , types == UIUserNotificationType() {
            notificationsEnabled = false
            promptForNotificationSettings(onViewController: sender, completion: failure)
        } else {
            success?()
        }
    }
    
    // Taking advantage of the side effect of the variable setting itself to false if there is an inconsistency
    @objc
    fileprivate func checkNotificationsEnabled() {
        _ = notificationsEnabled
    }
    
    fileprivate func promptForNotificationSettings(onViewController viewController: UIViewController, completion: (()->())?) {
        let alertController = UIAlertController(title: "Notification Error",
                                                message: "It appears that you have disallowed push notifications. Please enable them in your device settings if you wish to receive them.",
                                                preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings",
                                        style: .cancel,
                                        handler: {_ in
                                            UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
        })
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .destructive,
                                         handler: nil)
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        
        viewController.present(alertController,
                                             animated: true,
                                             completion: completion)
    }

    func disableNotificationFor(_ level: Level) {
        api?.unsubscribeFrom(ParkingEntity.level,
                             withUUID: level.uuid!,
                             predicate: NSPredicate(format: "CurrentCount = %d",0),
                             onActions: RemoteAction.update,
                             completion: { success in
                                if success {
                                   DataManager.sharedInstance.update(notificationsEnabled: false, forLevel: level)
                                }

        })
    }
    
    func enableNotificationFor(_ level: Level) {
        guard let structureName = level.structure?.name, let levelName = level.name else {return}
        api?.subscribeTo(ParkingEntity.level,
                         withUUID: level.uuid!,
                         predicate: NSPredicate(format: "CurrentCount = %d",0),
                         onActions: RemoteAction.update,
                         notificationText: "\(structureName) \(levelName) is now full",
                         completion: { success in
                            if success {
                                DataManager.sharedInstance.update(notificationsEnabled: true, forLevel: level)
                            }
        })

    }
    
    func fetchAndUpdateSubscriptions(withCompletion completion: @escaping ()->()) {
        fetchNotificationUUIDs({ uuids in
            DataManager.sharedInstance.update(notificationsEnabled: true,
                forUUIDs: uuids,
                withCompletion: completion)
        })
    }
}
