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
    
    fileprivate var container: CKContainer
    fileprivate var publicDB: CKDatabase
    fileprivate var privateDB: CKDatabase
    lazy fileprivate var subscriptionDictionary: [String : String] = self.initSubscriptionDict()
    fileprivate let subscriptionQueue = DispatchQueue(label: "Subscriptions-Queue", attributes: [])
    
    var presenting: Bool = false
    
    init(){
        container = CKContainer(identifier: "iCloud.com.stephenciauri.Chapman-Parking")
//        container = CKContainer.defaultContainer()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
    }
    
    // MARK: - CloudKit Account Status
    
    fileprivate func displayDevelopmentCloudKitAlert() {
        if !presenting {
            presenting = true
            let alertController = UIAlertController(title: "iCloud Required for Development Device", message: "Please login to your iCloud account to continue. If you are not on a development build and you believe you are reaching this screen in error, please email thecatalyticmind@gmail.com with details.", preferredStyle: .alert)
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                UIApplication.shared.openURL(URL(string:"prefs:root=CASTLE")!)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            alertController.addAction(settingsAction)
            alertController.addAction(cancelAction)
            DispatchQueue.main.async(execute: {
                UIApplication.shared.delegate?.window!?.rootViewController?.present(alertController, animated: true, completion: {_ in self.presenting = false})
            })
        }
    }
    
    
    /// Use this later when we want to make writes to CloudKit
    fileprivate func loginHandler(_ status: CKAccountStatus, error: NSError?){
        guard error == nil else{
            NSLog("error getting account status?")
            return
        }
        switch status{
        case .available:
            NSLog("logged in")
        case .couldNotDetermine:
            NSLog("cant determine")
            fallthrough
        case .noAccount:
            NSLog("no account")
            fallthrough
        case .restricted:
            NSLog("ur a kid lol")
            fallthrough
        default:
            displayDevelopmentCloudKitAlert()
        }
    }
    


    
    

    
    // MARK:- Subscriptions
    
    
    func saveSubscriptions() {
        let subscriptionData = NSKeyedArchiver.archivedData(withRootObject: subscriptionDictionary)
        UserDefaults.standard.set(subscriptionData, forKey: "subscriptions")
    }
    
    func unsubscribeFromAll(_ completion: @escaping () -> ()) {
        var completed = 0
        let totalSubscriptions = subscriptionDictionary.count
        if totalSubscriptions > 0 {
            for (key, subscriptionID) in subscriptionDictionary {
                privateDB.delete(withSubscriptionID: subscriptionID,
                                                   completionHandler: {(string, error) in
                                                    if let error = error {
                                                        NSLog(error.localizedDescription)
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
    
    func fetchSubscriptions(_ completion: @escaping (_ uuids: [String]) -> ()) {
        var subscribedUUIDs: [String] = []
        publicDB.fetchAllSubscriptions() { (subscriptions, error) in
            if let subscriptions = subscriptions {
                for subscription in subscriptions {
                    // Super duper hacky way to rebuild my subscriptionKey...
                    if let predicate = subscription.predicate?.predicateFormat,
                        let uuidRange = predicate.range(of: "(?<=; )(.*?)(?=:)", options: .regularExpression),
                        let predicateRange = predicate.range(of: "(?<=)(.*?)(?= AND)", options: .regularExpression){
                        let uuid = predicate.substring(with: uuidRange)
                        let predicateString = predicate.substring(with: predicateRange)
                        let type = RemoteAction(rawValue: Int(subscription.subscriptionOptions.rawValue))!.description
                        self.insert(uuid+predicateString+type, subscriptionID: subscription.subscriptionID)
                        subscribedUUIDs.append(uuid)
                    }
                }
            }
            completion(subscribedUUIDs)
        }
    }
    
    
    func forceUnsubscribeFromAll(_ completion: @escaping () -> ()) {
        publicDB.fetchAllSubscriptions() {(subscriptions, error) in
            if let subscriptions = subscriptions , !subscriptions.isEmpty {
                var completed = 0
                subscriptions.forEach(){
                    self.publicDB.delete(withSubscriptionID: $0.subscriptionID,
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
                NSLog(error.localizedDescription)
            } else {
                NSLog("Nothing to unsubscribe from")
                self.subscriptionDictionary = [:]
                completion()
            }
        }
    }
    
    func subscribeTo(_ entity: ParkingEntity, withUUID uuid: String?, predicate: NSPredicate, onActions action: RemoteAction, notificationText text: String, completion: @escaping (Bool)->()) {
        
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
        publicDB.save(subscription,
                                   completionHandler: {(subscription, error) in
                                    if let error = error {
                                        if error.localizedDescription.contains("duplicate") {
                                            NSLog("Catching duplicate")
                                            let subscriptionID = error.localizedDescription.components(separatedBy: "'")[1]
                                            successBlock(subscriptionID)
                                        } else {
                                            NSLog(error.localizedDescription)
                                            completion(false)
                                        }
                                    }
                                    if let subscription = subscription {
                                        successBlock(subscription.subscriptionID)
                                    }
                                    
        })
        
    }
    
    func unsubscribeFrom(_ entity: ParkingEntity, withUUID uuid: String?, predicate: NSPredicate, onActions action: RemoteAction, completion: @escaping (Bool)->()) {
        var subscriptionKey: String
        if let uuid = uuid {
            subscriptionKey = subscriptionKeyFor(uuid, predicate: predicate, action: action)
        } else {
            subscriptionKey = subscriptionKeyFor(entity, predicate: predicate, action: action)
        }
        
        if subscribedTo(subscriptionWithKey: subscriptionKey) {
            unsubscribeFrom(subscriptionWithKey: subscriptionKey, completion: completion)
        } else {
            // Returning success is okay since user's desired state is already true
            completion(true)
            NSLog("You are not currently subscribed to this event")
        }
        
    }
    
    fileprivate func initSubscriptionDict() -> [String : String] {
        if let subscriptionData = UserDefaults.standard.object(forKey: "subscriptions") as? Data,
            let subscriptions = NSKeyedUnarchiver.unarchiveObject(with: subscriptionData) as? [String : String] {
            return subscriptions
        } else {
            return [:]
        }
    }

    
    fileprivate func subscriptionFor(_ entity: ParkingEntity, withUUID uuid: String?, predicate: NSPredicate, onActions action: RemoteAction) -> CKSubscription {
        var ckAction: CKSubscriptionOptions
        switch action {
        case .add:
            ckAction = .firesOnRecordCreation
        case .update:
            ckAction = .firesOnRecordUpdate
        case .delete:
            ckAction = .firesOnRecordDeletion
        case .once:
            ckAction = .firesOnce
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
    
    fileprivate func subscriptionKeyFor(_ uuid: String, predicate: NSPredicate, action: RemoteAction) -> String {
        return uuid + predicate.description + action.description
    }
    
    fileprivate func subscriptionKeyFor(_ entity: ParkingEntity, predicate: NSPredicate, action: RemoteAction) -> String {
        return entity.cloudKitName + predicate.description + action.description
    }
    

    
    
    fileprivate func unsubscribeFrom(subscriptionWithKey key: String, completion: @escaping (Bool)->()) {
        if let subscriptionID = subscriptionID(withKey: key) {
            publicDB.delete(withSubscriptionID: subscriptionID,
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
    
    fileprivate func subscribedTo(subscriptionWithKey key: String)-> Bool {
        var contains: Bool = false
        subscriptionQueue.sync{
            contains = self.subscriptionDictionary[key] != nil
        }
        return contains
    }
    
    fileprivate func subscriptionID(withKey key: String) -> String? {
        var subscription: String?
        subscriptionQueue.sync{
            subscription = self.subscriptionDictionary[key]
        }
        return subscription
    }
    
    fileprivate func insert(_ key: String, subscriptionID: String) {
        subscriptionQueue.async{
            self.subscriptionDictionary[key] = subscriptionID
            self.saveSubscriptions()
        }
    }
    
    fileprivate func remove(subscriptionWithKey key: String) {
        subscriptionQueue.async{
            self.subscriptionDictionary[key] = nil
            self.saveSubscriptions()
        }
    }
    
    // MARK: - Data Source
    
    func executeQueryOperation(_ queryOperation: CKQueryOperation, withCounts counts: [CKCount] = [], completion :@escaping (([CKCount]) -> Void)){
        
        // Assign a record process handler
        var counts = counts
        queryOperation.recordFetchedBlock = { (record : CKRecord) -> Void in
            // Process each record
            counts.append(self.processCount(withRecord: record))
        }
        
        // Assign a completion handler
        queryOperation.queryCompletionBlock = { (cursor: CKQueryCursor?, error: Error?) -> Void in
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
        
        publicDB.add(queryOperation)
    }
    
    /// If no dates are provided, only the most recent counts are fetched
    func fetchCounts(fromLevelWithUUID uuid: String, starting startDate: Date? = nil, ending endDate: Date? = nil, completion: @escaping ([CKCount]?, NSError?) -> ()) {
        
        var resultLimit: Int?
        var datePredicates: [NSPredicate] = []
        if startDate == nil && endDate == nil {
            resultLimit = 1
        } else {
            if let startDate = startDate {
                datePredicates.append(NSPredicate(format: "UpdatedAt > %@", startDate as CVarArg))
            }
            if let endDate = endDate {
                datePredicates.append(NSPredicate(format: "UpdatedAt < %@", endDate as CVarArg))
                
            }
        }
        let id = CKRecordID(recordName: uuid)
        let ref = CKReference(recordID: id, action: .none)
        let levelPredicate = NSPredicate(format: "Level == %@", ref)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: datePredicates + [levelPredicate])
        let spotQuery = CKQuery(recordType: "ParkingSpotCount", predicate: predicate)
        let chronoSort = NSSortDescriptor(key: "UpdatedAt", ascending: false)
        spotQuery.sortDescriptors = [chronoSort]
        let spotQueryOperation = CKQueryOperation(query: spotQuery)
        
        // If there is a result limit, handle the results and query directly
        if let resultLimit = resultLimit {
            spotQueryOperation.resultsLimit = resultLimit
            spotQueryOperation.qualityOfService = .userInitiated
            spotQueryOperation.recordFetchedBlock = { record in
                completion([self.processCount(withRecord: record)], nil)
            }
            spotQueryOperation.queryCompletionBlock = { cursor, error in
                if let error = error {
                    print("\(error)")
                }
            }
            publicDB.add(spotQueryOperation)
        } else {
            self.executeQueryOperation(spotQueryOperation, completion: { counts in
                completion(counts, nil)
            })
            
        }
        
        
        
    }
    
    
    
    
    
    
    func generateReport(_ updateType: UpdateType, sinceDate: Date?, withBlock completion: @escaping ((CPReport?) -> Void)) {
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

    
    fileprivate func processCount(withRecord record: CKRecord)->CKCount{
        let ckID = record.recordID.recordName
        let numSpaces = record.object(forKey: "NumberOfSpaces") as! Int
        let timestamp = record.object(forKey: "UpdatedAt") as! Date
        return CKCount(uuid: ckID, count: numSpaces, timestamp: timestamp)
    }
    
    fileprivate func fetchParkingStructures(_ completion: @escaping ([CKStructure]?, NSError?) -> ()) {
        let query = CKQuery(recordType: "ParkingStructure", predicate: NSPredicate(value: true))
        publicDB.perform(query,
                              inZoneWith: nil,
                              completionHandler: { records, error in
                                if let e = error {
                                    completion(nil, e as NSError?)
                                    return
                                } else if let records = records {
                                    completion(self.parseParkingStructures(records), nil)
                                } else {
                                    completion(nil, nil)
                                }
        })
    }
    
    fileprivate func parseParkingStructures(_ records: [CKRecord]) -> [CKStructure] {
        var structures: [CKStructure] = []
        for record in records {
            guard let
                name = record.object(forKey: "Name") as? String,
                let location = record.object(forKey: "Location") as? CLLocation
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
    
    
    fileprivate func fetchLevels(fromStructureWithUUID uuid: String, withCompletion completion: @escaping ([CKLevel]?, NSError?) -> ()) {
        let id = CKRecordID(recordName: uuid)
        let ref = CKReference(recordID: id, action: .none)
        let levelQuery = CKQuery(recordType: "ParkingLevel", predicate: NSPredicate(format: "Structure == %@", ref))
        
        publicDB.perform(levelQuery,
                              inZoneWith: nil,
                              completionHandler: { records, error in
                                if let e = error {
                                    completion(nil, e as NSError?)
                                    return
                                } else if let records = records {
                                    completion(self.parseLevels(records), nil)
                                } else {
                                    completion(nil, nil)
                                }
        })
    }
    
    fileprivate func parseLevels(_ records: [CKRecord]) -> [CKLevel] {
        var levels: [CKLevel] = []
        for level in records {
            guard let
                levelName = level.object(forKey: "Name") as? String,
                let levelCap = level.object(forKey: "Capacity") as? Int,
                let levelCount = level.object(forKey: "CurrentCount") as? Int
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
