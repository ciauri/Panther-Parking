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
    
    var container: CKContainer
    var publicDB: CKDatabase
    
    var presenting: Bool = false
    
    init(){
        container = CKContainer(identifier: "iCloud.com.stephenciauri.Chapman-Parking")
//        container = CKContainer.defaultContainer()
        publicDB = container.publicCloudDatabase
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
        

        /**

        let query = CKQuery(recordType: "ParkingStructure", predicate: NSPredicate(value: true))
        publicDB.performQuery(query, inZoneWithID: nil, completionHandler: {results, error in
            if error != nil{
                NSLog("bork")
            }else{
                if let results = results{
                    let structureGroup = dispatch_group_create()
                    var structures: [CKStructure] = []
                    for record in results{
                        dispatch_group_enter(structureGroup)
                        
                        let structureName = record.objectForKey("Name") as! String
                        let structureLocation = record.objectForKey("Location") as! CLLocation
                        let lat = structureLocation.coordinate.latitude
                        let long = structureLocation.coordinate.longitude
                        let ckID = record.recordID.recordName
                        var structure = CKStructure(ckID: ckID, name: structureName, levels: [], lat: lat, long: long)
//                        structures.append()
                        
                        let ref = CKReference(record: record, action: CKReferenceAction.None)
                        let levelQuery = CKQuery(recordType: "ParkingLevel", predicate: NSPredicate(format: "Structure == %@", ref))

                        self.publicDB.performQuery(levelQuery, inZoneWithID: nil, completionHandler: {results, error in
                            if error != nil{
                                NSLog("ruhroh: \(error!)")
                            }else{
                                var levels: [CKLevel] = []
                                if let results = results{
                                    let levelGroup = dispatch_group_create()
                                    for record in results{
                                        dispatch_group_enter(levelGroup)
                                        
                                        // Build Level
                                        let levelName = record.objectForKey("Name") as! String
                                        let levelCap = record.objectForKey("Capacity") as! Int
                                        let levelCount = record.objectForKey("CurrentCount") as! Int
                                        let ckID = record.recordID.recordName

                                        var level = CKLevel(ckID: ckID, name: levelName, capacity: levelCap, counts: [], currentCount: levelCount)
                                        
                                        // Build Query
                                        let ref = CKReference(record: record, action: CKReferenceAction.None)
                                        var predicate = NSPredicate(format: "Level == %@", ref)
                                        var resultLimit: Int?
                                        switch updateType{
                                        case .All:
                                            break
                                        case .SinceLast:
                                            let latestPredicate = NSPredicate(format: "UpdatedAt > %@", sinceDate!)
                                            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, latestPredicate])
                                        case .Latest:
                                            resultLimit = 1
                                        }
                                        let spotQuery = CKQuery(recordType: "ParkingSpotCount", predicate: predicate)
                                        let chronoSort = NSSortDescriptor(key: "UpdatedAt", ascending: false)
                                        spotQuery.sortDescriptors = [chronoSort]
                                        
                                        // Build Operation
                                        let spotQueryOperation = CKQueryOperation(query: spotQuery)
                                        if let l = resultLimit{
                                            spotQueryOperation.resultsLimit = l
                                            spotQueryOperation.qualityOfService = .UserInitiated
                                        }

                                        
                                        self.executeQueryOperation(spotQueryOperation, completion: { counts in
                                            // Stupid struct hack due to invariance
                                            level.counts = counts.map({$0})
                                            NSLog("New tallys: \(structureName) \(levelName): \(counts.count))")
                                            levels.append(level)
                                            dispatch_group_leave(levelGroup)
                                        })

                                    }
                                    dispatch_group_notify(levelGroup, dispatch_get_main_queue(), {
                                        structure.levels = levels.map({$0})
                                        structures.append(structure)
                                        dispatch_group_leave(structureGroup)
                                    })
                                    
                                }
                            }
                        })
 
                    }
                    dispatch_group_notify(structureGroup, dispatch_get_main_queue(), {
                        let report = CKReport(structures: structures.map({$0}))
                        withBlock(report)
                    })
 
                }
            }
        })
         */
    }
}