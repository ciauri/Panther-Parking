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
        NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextDidSaveNotification, object: nil, queue: nil, usingBlock: {note in self.contextDidSaveNotificationHandler(note)})

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
    
    
    
    
    private func parkingStructureForName(name: String, moc: NSManagedObjectContext) -> Structure?{
        let request = NSFetchRequest(entityName: "Structure")
        request.predicate = NSPredicate(format: "name == %@", name)
        do{
            return try moc.executeFetchRequest(request).first as? Structure
        }catch{
            return nil
        }
    }
    
    private func levelInStructureWithName(structure: Structure, name: String, moc: NSManagedObjectContext) -> Level?{
        let request = NSFetchRequest(entityName: "Level")
        request.predicate = NSPredicate(format: "structure == %@ AND name == %@", structure, name)
        do{
            return try moc.executeFetchRequest(request).first as? Level
        }catch{
            return nil
        }
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
        do{
            return try (context.executeFetchRequest(request) as? [Count])?.first
        } catch {
            NSLog("error")
            return nil
        }
    }
    
    /// Fetches `Count` objects with UIMOC, returns chronologicall sorted list
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
    
    func updateCounts(updateType: UpdateType, withCompletion completion: (Bool -> ())? = nil){
        let backgroundContext = try! createPrivateQueueContext()
        var sinceDate: NSDate? = nil
        
        if updateType == .SinceLast{
            let request = NSFetchRequest(entityName: "Count")
            request.fetchLimit = 1
            let dateSort = NSSortDescriptor(key: "updatedAt", ascending: false)
            request.sortDescriptors = [dateSort]
            
            backgroundContext.performBlockAndWait({
                guard let sinceDate = try? (backgroundContext.executeFetchRequest(request).first as? Count)?.updatedAt
                    else {
                        NSLog("No counts")
                        completion?(false)
                        return
                }
//                sinceDate = (try! backgroundContext.executeFetchRequest(request).first as! Count).updatedAt
                NSLog("Getting counts since \(sinceDate)")
            })
        }
        
        api.generateReport(updateType, sinceDate: sinceDate, withBlock: {report in
            
            
            for structure in report.structures{
                var s: Structure
                
                if let structure = self.parkingStructureForName(structure.name!, moc: backgroundContext){
                    s = structure
                }else{
                    s = NSEntityDescription.insertNewObjectForEntityForName("Structure", inManagedObjectContext: backgroundContext) as! Structure
                    let loc = NSEntityDescription.insertNewObjectForEntityForName("Location", inManagedObjectContext: backgroundContext) as! Location
                    loc.lat = structure.lat
                    loc.long = structure.long
                    
                    s.location = loc
                    loc.structure = s
                    NSLog("New Structure")
                }
                
                s.name = structure.name
                
                for level in structure.levels{
                    var l: Level
                    
                    if let level = self.levelInStructureWithName(s, name: level.name!, moc: backgroundContext){
                        l = level
                    }else{
                        l = NSEntityDescription.insertNewObjectForEntityForName("Level", inManagedObjectContext: backgroundContext) as! Level
                        l.structure = s
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
                        //                        print("Before: \(s.name!) \(l.name!): \(c.availableSpaces) vs \(l.currentCount). Total Count: \(l.counts?.count)")
                        c.updatedAt = count.timestamp
                        c.level = l
                    }
                    if let c = latestCount{
                        l.updatedAt = c.timestamp
                    }
                    
//                    l.willChangeValueForKey("counts")
//                    l.didChangeValueForKey("counts")
                    
                }
            }
            try! backgroundContext.save()
            completion?(true)
//            backgroundContext.reset()
        })
        
    }
}