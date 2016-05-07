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
    
    var applicationDocumentsDirectory: NSURL
    var managedObjectModel: NSManagedObjectModel
    var persistentStoreCoordinator: NSPersistentStoreCoordinator
    var managedObjectContext: NSManagedObjectContext
    
    var autoRefreshInterval: Double = 60
    private weak var refreshTimer: NSTimer?
    
    var autoRefreshEnabled: Bool = true{
        didSet{
            if autoRefreshEnabled && (refreshTimer == nil){
                refreshTimer = NSTimer.scheduledTimerWithTimeInterval(self.autoRefreshInterval, target: self, selector: #selector(timerUpdateCounts), userInfo: nil, repeats: true)
            }else if !autoRefreshEnabled{
                refreshTimer?.invalidate()
            }
        }
    }
    
    private init(){
        applicationDocumentsDirectory = {
            // The directory the application uses to store the Core Data store file. This code uses a directory named "com.stephenciauri.Chapman_Parking" in the application's documents Application Support directory.
            let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            return urls[urls.count-1]
        }()
        
        managedObjectModel = {
            // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
            let modelURL = NSBundle.mainBundle().URLForResource("Chapman_Parking", withExtension: "momd")!
            return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
        
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let url = applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        let failureReason = "There was an error creating or loading the application's saved data."
        do {
            try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
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

        let coordinator = persistentStoreCoordinator
        managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.undoManager = nil
        managedObjectContext.persistentStoreCoordinator = coordinator
        
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(self.autoRefreshInterval, target: self, selector: #selector(timerUpdateCounts), userInfo: nil, repeats: true)

        NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextDidSaveNotification, object: nil, queue: nil, usingBlock: {note in self.contextDidSaveNotificationHandler(note)})

    }
    
    
    private func contextDidSaveNotificationHandler(notification: NSNotification){
        let sender = notification.object as! NSManagedObjectContext
        if sender !== managedObjectContext {
            managedObjectContext.performBlock {
                NSLog("Merging")
                self.managedObjectContext.mergeChangesFromContextDidSaveNotification(notification)
                self.saveContext()
            }
        }
    }
    
    // Creates a new Core Data stack and returns a managed object context associated with a private queue.
    private func createPrivateQueueContext() throws -> NSManagedObjectContext {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let storeURL = applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
        
        let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        
        context.performBlockAndWait() {
            
            context.persistentStoreCoordinator = coordinator
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
        updateCounts(.Latest)
    }
    
    
    
    func updateCounts(updateType: UpdateType){
        WebAPI.generateReport(updateType, withBlock: {report in
            let backgroundContext = try! self.createPrivateQueueContext()
            for structure in report.structures{
                var s: Structure
                
                if let structure = self.parkingStructureForName(structure.name!, moc: backgroundContext){
                    s = structure
                }else{
                    s = NSEntityDescription.insertNewObjectForEntityForName("Structure", inManagedObjectContext: backgroundContext) as! Structure
                    let loc = NSEntityDescription.insertNewObjectForEntityForName("Location", inManagedObjectContext: backgroundContext) as! Location
                    loc.lat = structure.lat
                    loc.long = structure.long
                }
                
                s.name = structure.name
                
                for level in structure.levels{
                    var l: Level
                    
                    if let level = self.levelInStructureWithName(s, name: level.name!, moc: backgroundContext){
                        l = level
                    }else{
                        l = NSEntityDescription.insertNewObjectForEntityForName("Level", inManagedObjectContext: backgroundContext) as! Level
                        l.structure = s
                    }
                    
                    l.name = level.name
                    l.capacity = level.capacity
                    
                    for count in level.counts{
                        let c = NSEntityDescription.insertNewObjectForEntityForName("Count", inManagedObjectContext: backgroundContext) as! Count
                        c.availableSpaces = count.count
                        c.updatedAt = count.timestamp
                        c.level = l

                    }
                }
                
            }
            try! backgroundContext.save()
        })
        
    }
}