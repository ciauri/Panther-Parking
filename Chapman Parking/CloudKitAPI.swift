//
//  CloudKitAPI.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/12/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation
import CloudKit

class CloudKitAPI: ParkingAPI{
    static let sharedInstance = CloudKitAPI() as ParkingAPI
    
    var container: CKContainer
    var publicDB: CKDatabase
    
    init(){
        container = CKContainer.defaultContainer()
        publicDB = container.publicCloudDatabase
    }

    
    func generateReport(updateType: UpdateType, sinceDate: NSDate?, withBlock: (CPReport -> Void)) {
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
                                        
                                        let levelName = record.objectForKey("Name") as! String
                                        let levelCap = record.objectForKey("Capacity") as! Int
                                        let levelCount = record.objectForKey("CurrentCount") as! Int
                                        let ckID = record.recordID.recordName
                                        
                                        var level = CKLevel(ckID: ckID, name: levelName, capacity: levelCap, counts: [], currentCount: levelCount)
                                        
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
                                        let spotQueryOperation = CKQueryOperation(query: spotQuery)
                                        if let l = resultLimit{
                                            spotQueryOperation.resultsLimit = l
                                        }


                                        
                                        var counts: [CKCount] = []
                                        spotQueryOperation.recordFetchedBlock = {(record: CKRecord) in
                                            let ckID = record.recordID.recordName
                                            let numSpaces = record.objectForKey("NumberOfSpaces") as! Int
                                            let timestamp = record.objectForKey("UpdatedAt") as! NSDate
                                            let count = CKCount(ckID: ckID, count: numSpaces, timestamp: timestamp)
                                            
                                            counts.append(count)
                                        }
                                        
                                        spotQueryOperation.queryCompletionBlock = {(cursor: CKQueryCursor?, error: NSError?) in
                                            if let _ = error{
                                                NSLog("op failed")
                                            }else{
                                                // Stupid struct hack due to invariance
                                                level.counts = counts.map({$0})
                                                levels.append(level)
                                                dispatch_group_leave(levelGroup)
                                            }
                                        }
                                        
                                        self.publicDB.addOperation(spotQueryOperation)
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

    }
}