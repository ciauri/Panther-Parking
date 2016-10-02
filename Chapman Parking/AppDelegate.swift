//
//  AppDelegate.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/4/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        injectDependencies()
        initializeData()


        
        DataManager.sharedInstance.autoRefreshEnabled = true
        NotificationService.sharedInstance.enableNotifications()
        LocationService.sharedInstance.startMonitoring()

//        api.forceUnsubscribeFromAll(){
//            NSLog("Unsubbed from server")
//            DataManager.sharedInstance.disableAllNotifications()
//        }
        
        themify()
        


        return true
    }
    
    func initializeData() {
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "initialized"){
            DataManager.sharedInstance.updateCounts(.all) { success in
                if success {
                    defaults.set(true, forKey: "initialized")
                } else {
                    NSLog("error updating counts")
                }
            }
            NSLog("Initializing Data")
        }else{
            DataManager.sharedInstance.updateCounts(UpdateType.sinceLast, withCompletion: nil)
            NSLog("Catching up")
        }
    }
    
    func injectDependencies() {
        let api: ParkingAPI = CloudKitAPI.sharedInstance
        DataManager.sharedInstance.api = api
        NotificationService.sharedInstance.api = api
        NotificationService.sharedInstance.modelDelegate = DataManager.sharedInstance
        LocationService.sharedInstance.eventHandlerDelegate = NotificationService.sharedInstance
    }
    
    func themify() {
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().barTintColor = UIColor(red: 143/255, green: 32/255, blue: 47/255, alpha: 1)
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName:UIColor.white]
        UINavigationBar.appearance().barStyle = UIBarStyle.black
        UISegmentedControl.appearance().tintColor = UIColor(red: 143/255, green: 32/255, blue: 47/255, alpha: 1)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("Failed to register for notifications: \(error.localizedDescription)")
        NotificationService.sharedInstance.notificationsEnabled = false
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NSLog("Successfully registered for push notifications")
//        NotificationService.notificationsEnabled = true

    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        NSLog("Received remote notification")
        
        /**
         Continue implementing this if I want to take an action in-app
        if let swiftInfo = userInfo as? [String : NSObject] {
            let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: swiftInfo)
            let alertBody = cloudKitNotification.alertBody
            if cloudKitNotification.notificationType == .Query {
                let recordID = (cloudKitNotification as! CKQueryNotification).recordID
            }
        }
         */
    }

    

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        if UserDefaults.standard.bool(forKey: "initialized"){
            DataManager.sharedInstance.updateCounts(UpdateType.sinceLast)
            NSLog("Catching up")
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
//        self.saveContext()
    }


}

