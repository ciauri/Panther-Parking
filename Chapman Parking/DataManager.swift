//
//  DataManager.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/5/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation
import CoreData

class DataManager{
    static let sharedInstance = DataManager()
    var api: ParkingAPI!

    
    var autoRefreshInterval: Double = 60
//    private weak var refreshTimer: NSTimer?
    
    var autoRefreshEnabled: Bool = true{
        didSet{
            if autoRefreshEnabled && (refreshTimer == nil){
                refreshTimer = NSTimer.scheduledTimerWithTimeInterval(self.autoRefreshInterval, target: self, selector: #selector(timerUpdateCounts), userInfo: nil, repeats: true)
            }else if !autoRefreshEnabled{
                refreshTimer?.invalidate()
            }
        }
    }
    
    lazy var refreshTimer: NSTimer? = {
        let timer = NSTimer.scheduledTimerWithTimeInterval(self.autoRefreshInterval, target: self, selector: #selector(timerUpdateCounts), userInfo: nil, repeats: true)
        
        return timer
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
    // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
    let modelURL = NSBundle.mainBundle().URLForResource("Chapman_Parking", withExtension: "momd")!
    return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        let failureReason = "There was an error creating or loading the application's saved data."
        do {
            try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: [NSInferMappingModelAutomaticallyOption: true, NSMigratePersistentStoresAutomaticallyOption: true])
            return persistentStoreCoordinator
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
    }()

    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.stephenciauri.Chapman_Parking" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.undoManager = nil
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextDidSaveNotification, object: nil, queue: nil, usingBlock: self.contextDidSaveNotificationHandler)

        return managedObjectContext
    }()
    
    
    private func contextDidSaveNotificationHandler(notification: NSNotification){
        let sender = notification.object as! NSManagedObjectContext
        if sender !== managedObjectContext {
            managedObjectContext.performBlock {
//                print(self.managedObjectContext.hasChanges)
                NSLog("Merging")
                self.managedObjectContext.mergeChangesFromContextDidSaveNotification(notification)
//                print(self.managedObjectContext.hasChanges)
//                try! self.managedObjectContext.save()
            }
        }
    }
    
    // Creates a new Core Data stack and returns a managed object context associated with a private queue.
    func createPrivateQueueContext() throws -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        
        context.performBlockAndWait() {
            
            context.persistentStoreCoordinator = self.persistentStoreCoordinator
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            context.undoManager = nil
        }
        
        return context
    }
    
    // MARK: - Core Data Saving support
    
    private func saveContext () {
        
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
                NSLog("Saved")
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    
    enum ParkingObject{
        case Structure
        case Level
    }
    
    
    
    private func structureWith(uuid: String, moc: NSManagedObjectContext) -> Structure? {
        let request = NSFetchRequest(entityName: "Structure")
        request.predicate = NSPredicate(format: "uuid == %@", uuid)
        var structure: Structure?
        moc.performBlockAndWait({
            do{
                structure = try moc.executeFetchRequest(request).first as? Structure
            }catch{
                fatalError("WAT")
            }
        })
        
        return structure
        
    }
    
    private func parkingStructureForName(name: String, moc: NSManagedObjectContext) -> Structure?{
        let request = NSFetchRequest(entityName: "Structure")
        request.predicate = NSPredicate(format: "name == %@", name)
        var structure: Structure?
        moc.performBlockAndWait({
            do{
                structure = try moc.executeFetchRequest(request).first as? Structure
            }catch{
                fatalError("WAT")
            }
        })
        
        return structure
    }
    
    private func levelWith(uuid: String, moc: NSManagedObjectContext) -> Level? {
        let request = NSFetchRequest(entityName: "Level")
        request.predicate = NSPredicate(format: "uuid == %@", uuid)
        var level: Level?
        moc.performBlockAndWait({
            do{
                level = try moc.executeFetchRequest(request).first as? Level
            }catch{
                fatalError("WAT")
            }
        })
        
        return level
    }
    
    private func levelInStructureWithName(structure: Structure, name: String, moc: NSManagedObjectContext) -> Level?{
        let request = NSFetchRequest(entityName: "Level")
        request.predicate = NSPredicate(format: "structure == %@ AND name == %@", structure, name)
        var level: Level?
        moc.performBlockAndWait({
            do{
                level = try moc.executeFetchRequest(request).first as? Level
            }catch{
                fatalError("WAT")
            }
        })
        
        return level
    }
    
    
    
    @objc
    private func timerUpdateCounts(){
        updateCounts(.SinceLast)
    }
    
    func mostRecentCount(fromDate date: NSDate, onLevel level: Level, usingContext context: NSManagedObjectContext) -> Count? {
        let request = NSFetchRequest(entityName: "Count")
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        request.predicate = NSPredicate(format: "(level == %@) AND (updatedAt <= %@)", level, date)
        request.fetchLimit = 1
        
        var count: Count?
        context.performBlockAndWait({
            do{
                count = try (context.executeFetchRequest(request) as? [Count])?.first
            } catch {
                NSLog("error")
            }
        })
        return count
    }
    
    /// Fetches `Count` objects with UIMOC, returns chronologically sorted list
    func countsOn(level: Level, since date: NSDate) -> [Count] {
        let context = DataManager.sharedInstance.managedObjectContext
        let request = NSFetchRequest(entityName: "Count")
        let chronoSort = NSSortDescriptor(key: "updatedAt", ascending: true)
        request.sortDescriptors = [chronoSort]
        request.predicate = NSPredicate(format: "(level == %@) AND (updatedAt >= %@)", level, date)
        
        var counts: [Count] = []
        context.performBlockAndWait({
            do{
                counts = try context.executeFetchRequest(request) as! [Count]
            } catch {
                NSLog("error with fetch")
            }
        })
        
        return counts
    }
    
    private func process(structure: CPStructure, withContext context: NSManagedObjectContext?) {
        var moc: NSManagedObjectContext
        if let context = context {
            moc = context
        } else {
            moc = try! createPrivateQueueContext()
        }
        
        moc.performBlock({
            var s: Structure
            if let structure = self.structureWith(structure.uuid, moc: moc) {
                s = structure
            } else {
                s = NSEntityDescription.insertNewObjectForEntityForName("Structure", inManagedObjectContext: moc) as! Structure
                let loc = NSEntityDescription.insertNewObjectForEntityForName("Location", inManagedObjectContext: moc) as! Location
                s.location = loc
                s.uuid = structure.uuid
                NSLog("New Structure")
            }
            
            s.location?.lat = structure.lat
            s.location?.long = structure.long
            s.name = structure.name
            
            try! moc.save()
        })
    }
    
    private func process(level: CPLevel, inStructure structure: Structure, withContext context: NSManagedObjectContext?) {
        var moc: NSManagedObjectContext
        if let context = context {
            moc = context
        } else {
            moc = try! createPrivateQueueContext()
        }
        
        moc.performBlock({
            var l: Level
            if let level = self.levelWith(level.uuid, moc: moc){
                l = level
            }else{
                l = NSEntityDescription.insertNewObjectForEntityForName("Level", inManagedObjectContext: moc) as! Level
                l.structure = structure
                l.uuid = level.uuid
                NSLog("New Level")
            }
            
            l.name = level.name
            l.capacity = level.capacity
            l.currentCount = level.currentCount
            try! moc.save()
        })
    }
    
    private func process(counts: [CPCount], onLevel level: Level, withContext context: NSManagedObjectContext?, completion: ([Count] -> ())?){
        var moc: NSManagedObjectContext
        if let context = context {
            moc = context
        } else {
            moc = try! createPrivateQueueContext()
        }
        var countArray: [Count] = []
        moc.performBlock({
            for count in counts{
                let c = NSEntityDescription.insertNewObjectForEntityForName("Count", inManagedObjectContext: moc) as! Count
                c.availableSpaces = count.count
                c.updatedAt = count.timestamp
                c.level = moc.objectWithID(level.objectID) as? Level
                c.uuid = count.uuid
                countArray.append(c)
            }
            try! moc.save()
            completion?(countArray)
        })
    }
    
    func update(level: Level, startDate start: NSDate?, endDate end: NSDate?, completion: ([Count] -> ())?){
        guard let uuid = level.uuid
            else {
                NSLog("Level does not have a uuid... whoops")
                return
        }
        
        api.fetchCounts(fromLevelWithUUID: uuid,
                        starting: start,
                        ending: end,
                        completion: {counts, error in
                            if let error = error {
                                NSLog("\(error)")
                                completion?([])
                            } else if let counts = counts {
                                self.process(counts.map{$0},
                                    onLevel: level,
                                    withContext: nil,
                                    completion: completion)
                            }
        })
    }

    
    /// TODO: Re-implement using above new functions
    func updateCounts(updateType: UpdateType, withCompletion completion: (Bool -> ())? = nil){
        let backgroundContext = try! createPrivateQueueContext()
        var sinceDate: NSDate? = nil
        
        if updateType == .SinceLast{
            let request = NSFetchRequest(entityName: "Count")
            request.fetchLimit = 1
            let dateSort = NSSortDescriptor(key: "updatedAt", ascending: false)
            request.sortDescriptors = [dateSort]
            
            backgroundContext.performBlockAndWait({
                guard let date = try? (backgroundContext.executeFetchRequest(request).first as? Count)?.updatedAt
                    else {
                        NSLog("No counts")
                        completion?(false)
                        return
                }
                sinceDate = date
                NSLog("Getting counts since \(sinceDate)")
            })
        }
        
        api.generateReport(updateType, sinceDate: sinceDate, withBlock: {report in
            
            backgroundContext.performBlock({
                for structure in report.structures{
                    var s: Structure
                    
                    if let structure = structure as? CKStructure {
                        NSLog(structure.uuid)
                    }
                    
                    if let structure = self.structureWith(structure.uuid, moc: backgroundContext){
                        s = structure
                    }else{
                        s = NSEntityDescription.insertNewObjectForEntityForName("Structure", inManagedObjectContext: backgroundContext) as! Structure
                        let loc = NSEntityDescription.insertNewObjectForEntityForName("Location", inManagedObjectContext: backgroundContext) as! Location
                        loc.lat = structure.lat
                        loc.long = structure.long
                        
                        s.location = loc
                        s.uuid = structure.uuid
                        loc.structure = s
                        NSLog("New Structure")
                    }
                    
                    s.name = structure.name
                    
                    for level in structure.levels{
                        var l: Level
                        
                        if let level = self.levelWith(level.uuid, moc: backgroundContext){
                            l = level
                        }else{
                            l = NSEntityDescription.insertNewObjectForEntityForName("Level", inManagedObjectContext: backgroundContext) as! Level
                            l.structure = s
                            l.uuid = level.uuid
                            NSLog("New Level")
                        }
                        
                        l.name = level.name
                        l.capacity = level.capacity
                        l.currentCount = level.currentCount
                        
                        var latestCount: CPCount? = nil
                        
                        for count in level.counts{
                            
                            if latestCount == nil || latestCount?.timestamp?.compare(count.timestamp!) == NSComparisonResult.OrderedAscending{
                                latestCount = count
                            }
                            
                            let c = NSEntityDescription.insertNewObjectForEntityForName("Count", inManagedObjectContext: backgroundContext) as! Count
                            c.availableSpaces = count.count
                            c.updatedAt = count.timestamp
                            c.level = l
                            c.uuid = count.uuid
                        }
                        if let c = latestCount{
                            l.updatedAt = c.timestamp
                        }
                        
                    }
                }
                try! backgroundContext.save()
                completion?(true)
            })
        })
        
    }
}