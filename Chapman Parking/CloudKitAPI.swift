//
//  CloudKitAPI.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/12/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

class CloudKitAPI: ParkingAPI{
    static let sharedInstance = CloudKitAPI() as ParkingAPI
    
    private var container: CKContainer
    private var publicDB: CKDatabase
    private var privateDB: CKDatabase
    lazy private var subscriptionDictionary: [String : String] = self.initSubscriptionDict()
    private let subscriptionQueue = dispatch_queue_create("Subscriptions-Queue", DISPATCH_QUEUE_SERIAL)
    
    var presenting: Bool = false
    
    init(){
        container = CKContainer(identifier: "iCloud.com.stephenciauri.Chapman-Parking")
//        container = CKContainer.defaultContainer()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }
    
    // MARK: - CloudKit Account Status
    
    private func displayDevelopmentCloudKitAlert() {
        if !presenting {
            presenting = true
            let alertController = UIAlertController(title: "iCloud Required for Development Device", message: "Please login to your iCloud account to continue. If you are not on a development build and you believe you are reaching this screen in error, please email thecatalyticmind@gmail.com with details.", preferredStyle: .Alert)
            let settingsAction = UIAlertAction(title: "Settings", style: .Default) { (_) -> Void in
                UIApplication.sharedApplication().openURL(NSURL(string:"prefs:root=CASTLE")!)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
            alertController.addAction(settingsAction)
            alertController.addAction(cancelAction)
            dispatch_async(dispatch_get_main_queue(), {
                UIApplication.sharedApplication().delegate?.window!?.rootViewController?.presentViewController(alertController, animated: true, completion: {_ in self.presenting = false})
            })
        }
    }
    
    
    /// Use this later when we want to make writes to CloudKit
    private func loginHandler(status: CKAccountStatus, error: NSError?){
        guard error == nil else{
            NSLog("error getting account status?")
            return
        }
        switch status{
        case .Available:
            NSLog("logged in")
        case .CouldNotDetermine:
            NSLog("cant determine")
            fallthrough
        case .NoAccount:
            NSLog("no account")
            fallthrough
        case .Restricted:
            NSLog("ur a kid lol")
            fallthrough
        default:
            displayDevelopmentCloudKitAlert()
        }
    }
    


    
    

    
    // MARK:- Subscriptions
    
    
    func saveSubscriptions() {
        let subscriptionData = NSKeyedArchiver.archivedDataWithRootObject(subscriptionDictionary)
        NSUserDefaults.standardUserDefaults().setObject(subscriptionData, forKey: "subscriptions")
    }
    
    func unsubscribeFromAll(completion: () -> ()) {
        var completed = 0
        let totalSubscriptions = subscriptionDictionary.count
        if totalSubscriptions > 0 {
            for (key, subscriptionID) in subscriptionDictionary {
                privateDB.deleteSubscriptionWithID(subscriptionID,
                                                   completionHandler: {(string, error) in
                                                    if let error = error {
                                                        NSLog(error.debugDescription)
                                                    } else if let string = string{
                                                        NSLog("Successfully unsubscribed from \(string)")
                                                        self.remove(subscriptionWithKey: key)
                                                    }
                                                    completed += 1
                                                    if completed == totalSubscriptions {
                                                        NSLog("Unsubscribed from everything")
                                                        completion()
                                                    }
                })
            }
        } else {
            NSLog("Nothing to unsubscribe from")
            completion()
        }
        
    }
    
    func fetchSubscriptions(completion: (uuids: [String]) -> ()) {
        var subscribedUUIDs: [String] = []
        publicDB.fetchAllSubscriptionsWithCompletionHandler() { (subscriptions, error) in
            if let subscriptions = subscriptions {
                for subscription in subscriptions {
                    // Super duper hacky way to rebuild my subscriptionKey...
                    if let predicate = subscription.predicate?.predicateFormat,
                        uuidRange = predicate.rangeOfString("(?<=; )(.*?)(?=:)", options: .RegularExpressionSearch),
                        predicateRange = predicate.rangeOfString("(?<=)(.*?)(?= AND)", options: .RegularExpressionSearch){
                        let uuid = predicate.substringWithRange(uuidRange)
                        let predicateString = predicate.substringWithRange(predicateRange)
                        let type = RemoteAction(rawValue: Int(subscription.subscriptionOptions.rawValue))!.description
                        self.insert(uuid+predicateString+type, subscriptionID: subscription.subscriptionID)
                        subscribedUUIDs.append(uuid)
                    }
                }
            }
            completion(uuids: subscribedUUIDs)
        }
    }
    
    
    func forceUnsubscribeFromAll(completion: () -> ()) {
        publicDB.fetchAllSubscriptionsWithCompletionHandler() {(subscriptions, error) in
            if let subscriptions = subscriptions where !subscriptions.isEmpty {
                var completed = 0
                subscriptions.forEach(){
                    self.publicDB.deleteSubscriptionWithID($0.subscriptionID,
                        completionHandler: { (string, error) in
                            NSLog("Successfully unsubscribed from subscription with ID: \(string)")
                            completed += 1
                            if completed == subscriptions.count {
                                NSLog("Unsubscribed from everything")
                                self.subscriptionDictionary = [:]
                                completion()
                            }
                    })
                }
            } else if let error = error {
                NSLog(error.debugDescription)
            } else {
                NSLog("Nothing to unsubscribe from")
                self.subscriptionDictionary = [:]
                completion()
            }
        }
    }
    
    func subscribeTo(entity: ParkingEntity, withUUID uuid: String?, predicate: NSPredicate, onActions action: RemoteAction, notificationText text: String, completion: (Bool)->()) {
        
        let subscription = subscriptionFor(entity, withUUID: uuid, predicate: predicate, onActions: action)
        var subscriptionKey: String
        if let uuid = uuid {
            subscriptionKey = subscriptionKeyFor(uuid, predicate: predicate, action: action)
        } else {
            subscriptionKey = subscriptionKeyFor(entity, predicate: predicate, action: action)
        }
        let notificationInfo = CKNotificationInfo()
        //        notificationInfo.alertLocalizationKey = "level-empty-message"
        //        notificationInfo.alertLocalizationArgs = ["Structure.Name","Name"]
        notificationInfo.alertBody = text
        notificationInfo.shouldBadge = false
        subscription.notificationInfo = notificationInfo
        let successBlock: (String) -> () = {subscriptionID in
            self.insert(subscriptionKey, subscriptionID: subscriptionID)
            NSLog("Successfully subscribed to \(subscriptionKey)")
            completion(true)
        }
        publicDB.saveSubscription(subscription,
                                   completionHandler: {(subscription, error) in
                                    if let error = error {
                                        if error.description.containsString("duplicate") {
                                            NSLog("Catching duplicate")
                                            let subscriptionID = error.description.componentsSeparatedByString("'")[1]
                                            successBlock(subscriptionID)
                                        } else {
                                            NSLog(error.debugDescription)
                                            completion(false)
                                        }
                                    }
                                    if let subscription = subscription {
                                        successBlock(subscription.subscriptionID)
                                    }
                                    
        })
        
    }
    
    func unsubscribeFrom(entity: ParkingEntity, withUUID uuid: String?, predicate: NSPredicate, onActions action: RemoteAction, completion: (Bool)->()) {
        var subscriptionKey: String
        if let uuid = uuid {
            subscriptionKey = subscriptionKeyFor(uuid, predicate: predicate, action: action)
        } else {
            subscriptionKey = subscriptionKeyFor(entity, predicate: predicate, action: action)
        }
        
        if subscribedTo(subscriptionWithKey: subscriptionKey) {
            unsubscribeFrom(subscriptionWithKey: subscriptionKey, completion: completion)
        } else {
            completion(false)
            NSLog("You are not currently subscribed to this event")
        }
        
    }
    
    private func initSubscriptionDict() -> [String : String] {
        if let subscriptionData = NSUserDefaults.standardUserDefaults().objectForKey("subscriptions") as? NSData,
            subscriptions = NSKeyedUnarchiver.unarchiveObjectWithData(subscriptionData) as? [String : String] {
            return subscriptions
        } else {
            return [:]
        }
    }

    
    private func subscriptionFor(entity: ParkingEntity, withUUID uuid: String?, predicate: NSPredicate, onActions action: RemoteAction) -> CKSubscription {
        var ckAction: CKSubscriptionOptions
        switch action {
        case .Add:
            ckAction = .FiresOnRecordCreation
        case .Update:
            ckAction = .FiresOnRecordUpdate
        case .Delete:
            ckAction = .FiresOnRecordDeletion
        case .Once:
            ckAction = .FiresOnce
        }
        
        var predicates = [predicate]
        if let uuid = uuid {
            let id = CKRecordID(recordName: uuid)
            predicates.append(NSPredicate(format: "recordID = %@", id))
        }
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        return CKSubscription(recordType: entity.cloudKitName,
                                          predicate: compoundPredicate,
                                          options: ckAction)
    }
    
    private func subscriptionKeyFor(uuid: String, predicate: NSPredicate, action: RemoteAction) -> String {
        return uuid + predicate.description + action.description
    }
    
    private func subscriptionKeyFor(entity: ParkingEntity, predicate: NSPredicate, action: RemoteAction) -> String {
        return entity.cloudKitName + predicate.description + action.description
    }
    

    
    
    private func unsubscribeFrom(subscriptionWithKey key: String, completion: (Bool)->()) {
        if let subscriptionID = subscriptionID(withKey: key) {
            publicDB.deleteSubscriptionWithID(subscriptionID,
                                              completionHandler: {(string, error) in
                                                if error != nil {
                                                    NSLog(error.debugDescription)
                                                    completion(false)
                                                } else {
                                                    self.remove(subscriptionWithKey: key)
                                                    NSLog("Successfully unsubscribed from \(key)")
                                                    completion(true)
                                                }
            })
        }
    }
    
    private func subscribedTo(subscriptionWithKey key: String)-> Bool {
        var contains: Bool = false
        dispatch_sync(subscriptionQueue){
            contains = self.subscriptionDictionary[key] != nil
        }
        return contains
    }
    
    private func subscriptionID(withKey key: String) -> String? {
        var subscription: String?
        dispatch_sync(subscriptionQueue){
            subscription = self.subscriptionDictionary[key]
        }
        return subscription
    }
    
    private func insert(key: String, subscriptionID: String) {
        dispatch_async(subscriptionQueue){
            self.subscriptionDictionary[key] = subscriptionID
            self.saveSubscriptions()
        }
    }
    
    private func remove(subscriptionWithKey key: String) {
        dispatch_async(subscriptionQueue){
            self.subscriptionDictionary[key] = nil
            self.saveSubscriptions()
        }
    }
    
    // MARK: - Data Source
    
    func executeQueryOperation(queryOperation: CKQueryOperation, withCounts counts: [CKCount] = [], completion :(([CKCount]) -> Void)){
        
        // Assign a record process handler
        var counts = counts
        queryOperation.recordFetchedBlock = { (record : CKRecord) -> Void in
            // Process each record
            counts.append(self.processCount(withRecord: record))
        }
        
        // Assign a completion handler
        queryOperation.queryCompletionBlock = { (cursor: CKQueryCursor?, error: NSError?) -> Void in
            guard error==nil else {
                // Handle the error
                NSLog("QO error")
                return
            }
            if let queryCursor = cursor {
                let queryCursorOperation = CKQueryOperation(cursor: queryCursor)
                self.executeQueryOperation(queryCursorOperation, withCounts: counts, completion: completion)
            }else{
                completion(counts)
            }
        }
        
        publicDB.addOperation(queryOperation)
    }
    
    /// If no dates are provided, only the most recent counts are fetched
    func fetchCounts(fromLevelWithUUID uuid: String, starting startDate: NSDate? = nil, ending endDate: NSDate? = nil, completion: ([CKCount]?, NSError?) -> ()) {
        
        var resultLimit: Int?
        var datePredicates: [NSPredicate] = []
        if startDate == nil && endDate == nil {
            resultLimit = 1
        } else {
            if let startDate = startDate {
                datePredicates.append(NSPredicate(format: "UpdatedAt > %@", startDate))
            }
            if let endDate = endDate {
                datePredicates.append(NSPredicate(format: "UpdatedAt < %@", endDate))
                
            }
        }
        let id = CKRecordID(recordName: uuid)
        let ref = CKReference(recordID: id, action: .None)
        let levelPredicate = NSPredicate(format: "Level == %@", ref)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: datePredicates + [levelPredicate])
        let spotQuery = CKQuery(recordType: "ParkingSpotCount", predicate: predicate)
        let chronoSort = NSSortDescriptor(key: "UpdatedAt", ascending: false)
        spotQuery.sortDescriptors = [chronoSort]
        let spotQueryOperation = CKQueryOperation(query: spotQuery)
        
        // If there is a result limit, handle the results and query directly
        if let resultLimit = resultLimit {
            spotQueryOperation.resultsLimit = resultLimit
            spotQueryOperation.qualityOfService = .UserInitiated
            spotQueryOperation.recordFetchedBlock = { record in
                completion([self.processCount(withRecord: record)], nil)
            }
            spotQueryOperation.queryCompletionBlock = { cursor, error in
                if let error = error {
                    print("\(error)")
                }
            }
            publicDB.addOperation(spotQueryOperation)
        } else {
            self.executeQueryOperation(spotQueryOperation, completion: { counts in
                completion(counts, nil)
            })
            
        }
        
        
        
    }
    
    
    
    
    
    
    func generateReport(updateType: UpdateType, sinceDate: NSDate?, withBlock completion: (CPReport? -> Void)) {
        //        container.accountStatusWithCompletionHandler(loginHandler)
        
        fetchParkingStructures({ structures, error in
            guard let structures = structures
                else{
                    NSLog("Error fetching structures")
                    self.displayDevelopmentCloudKitAlert()
                    completion(nil)
                    return
            }
            completion(CKReport(structures: structures.map{$0}))
            structures.forEach({ structure in
                
                
                self.fetchLevels(fromStructureWithUUID: structure.uuid,
                    withCompletion: { levels, error in
                        guard let levels = levels
                            else{
                                NSLog("Error fetching levels")
                                self.displayDevelopmentCloudKitAlert()
                                completion(nil)
                                return
                        }
                        
                        var structure = structure
                        structure.levels = levels.map{$0}
                        completion(CKReport(structures: [structure]))
                        levels.forEach({ level in
                            
                            
                            self.fetchCounts(fromLevelWithUUID: level.uuid,
                                starting: sinceDate,
                                ending: nil,
                                completion: { counts, error in
                                    guard let counts = counts
                                        else{
                                            NSLog("Error fetching counts")
                                            self.displayDevelopmentCloudKitAlert()
                                            completion(nil)
                                            return
                                    }
                                    
                                    var level = level
                                    level.counts = counts.map{$0}
                                    structure.levels = [level]
                                    completion(CKReport(structures: [structure]))
                            })
                            
                        })
                        
                })
            })
            
        })
    }

    
    private func processCount(withRecord record: CKRecord)->CKCount{
        let ckID = record.recordID.recordName
        let numSpaces = record.objectForKey("NumberOfSpaces") as! Int
        let timestamp = record.objectForKey("UpdatedAt") as! NSDate
        return CKCount(uuid: ckID, count: numSpaces, timestamp: timestamp)
    }
    
    private func fetchParkingStructures(completion: ([CKStructure]?, NSError?) -> ()) {
        let query = CKQuery(recordType: "ParkingStructure", predicate: NSPredicate(value: true))
        publicDB.performQuery(query,
                              inZoneWithID: nil,
                              completionHandler: { records, error in
                                if let e = error {
                                    completion(nil, e)
                                    return
                                } else if let records = records {
                                    completion(self.parseParkingStructures(records), nil)
                                } else {
                                    completion(nil, nil)
                                }
        })
    }
    
    private func parseParkingStructures(records: [CKRecord]) -> [CKStructure] {
        var structures: [CKStructure] = []
        for record in records {
            guard let
                name = record.objectForKey("Name") as? String,
                location = record.objectForKey("Location") as? CLLocation
                else{
                    NSLog("Cant parse structure. Model issue")
                    return []
            }
            let lat = location.coordinate.latitude,
                long = location.coordinate.longitude,
                ckID = record.recordID.recordName
            
            let newStructure = CKStructure(uuid: ckID, name: name, levels: [], lat: lat, long: long)
            structures.append(newStructure)
        }
        return structures
    }
    
    
    private func fetchLevels(fromStructureWithUUID uuid: String, withCompletion completion: ([CKLevel]?, NSError?) -> ()) {
        let id = CKRecordID(recordName: uuid)
        let ref = CKReference(recordID: id, action: .None)
        let levelQuery = CKQuery(recordType: "ParkingLevel", predicate: NSPredicate(format: "Structure == %@", ref))
        
        publicDB.performQuery(levelQuery,
                              inZoneWithID: nil,
                              completionHandler: { records, error in
                                if let e = error {
                                    completion(nil, e)
                                    return
                                } else if let records = records {
                                    completion(self.parseLevels(records), nil)
                                } else {
                                    completion(nil, nil)
                                }
        })
    }
    
    private func parseLevels(records: [CKRecord]) -> [CKLevel] {
        var levels: [CKLevel] = []
        for level in records {
            guard let
                levelName = level.objectForKey("Name") as? String,
                levelCap = level.objectForKey("Capacity") as? Int,
                levelCount = level.objectForKey("CurrentCount") as? Int
                else{
                    NSLog("Error parsing levels. Model issue")
                    return []
            }
            
            let ckID = level.recordID.recordName
            let newLevel = CKLevel(uuid: ckID, name: levelName, capacity: levelCap, counts: [], currentCount: levelCount)
            levels.append(newLevel)
        }
        return levels
    }
    
   }