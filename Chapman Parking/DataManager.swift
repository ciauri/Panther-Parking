//
//  DataManager.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/5/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation
import CoreData

class DataManager: NotificationModelDelegate{
    static let sharedInstance = DataManager()
    var api: ParkingAPI!

    
    var autoRefreshInterval: Double = 60
//    private weak var refreshTimer: NSTimer?
    
    var autoRefreshEnabled: Bool = true{
        didSet{
            if autoRefreshEnabled && (refreshTimer == nil){
                refreshTimer = Timer.scheduledTimer(timeInterval: self.autoRefreshInterval, target: self, selector: #selector(timerUpdateCounts), userInfo: nil, repeats: true)
            }else if !autoRefreshEnabled{
                refreshTimer?.invalidate()
            }
        }
    }
    
    lazy var refreshTimer: Timer? = {
        let timer = Timer.scheduledTimer(timeInterval: self.autoRefreshInterval, target: self, selector: #selector(timerUpdateCounts), userInfo: nil, repeats: true)
        
        return timer
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
    // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
    let modelURL = Bundle.main.url(forResource: "Chapman_Parking", withExtension: "momd")!
    return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        let failureReason = "There was an error creating or loading the application's saved data."
        do {
            try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: [NSInferMappingModelAutomaticallyOption: true, NSMigratePersistentStoresAutomaticallyOption: true])
            return persistentStoreCoordinator
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
    }()

    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.stephenciauri.Chapman_Parking" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjectContext.undoManager = nil
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextDidSave, object: nil, queue: nil, using: self.contextDidSaveNotificationHandler)

        return managedObjectContext
    }()
    
    
    fileprivate func contextDidSaveNotificationHandler(_ notification: Notification){
        let sender = notification.object as! NSManagedObjectContext
        if sender !== managedObjectContext {
            managedObjectContext.perform {
                self.managedObjectContext.mergeChanges(fromContextDidSave: notification)
                self.saveContext()
            }
        }
    }
    
    // Creates a new Core Data stack and returns a managed object context associated with a private queue.
    func createPrivateQueueContext() throws -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        context.performAndWait() {
            context.persistentStoreCoordinator = self.persistentStoreCoordinator
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            context.undoManager = nil
        }
        
        return context
    }
    
    // MARK: - Core Data Saving support
    
    fileprivate func saveContext() {
        
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
        case structure
        case level
    }
    
    
    // MARK: - Convenience methods
    fileprivate func structureWith(_ uuid: String, moc: NSManagedObjectContext) -> Structure? {
        let request = NSFetchRequest<Structure>(entityName: "Structure")
        request.predicate = NSPredicate(format: "uuid == %@", uuid)
        var structure: Structure?
        moc.performAndWait({
            do{
                structure = try moc.fetch(request).first
            }catch{
                fatalError("WAT")
            }
        })
        
        return structure
        
    }
    
    fileprivate func parkingStructureForName(_ name: String, moc: NSManagedObjectContext) -> Structure?{
        let request = NSFetchRequest<Structure>(entityName: "Structure")
        request.predicate = NSPredicate(format: "name == %@", name)
        var structure: Structure?
        moc.performAndWait({
            do{
                structure = try moc.fetch(request).first
            }catch{
                fatalError("WAT")
            }
        })
        
        return structure
    }
    
    fileprivate func levelWith(_ uuid: String, moc: NSManagedObjectContext) -> Level? {
        let request = NSFetchRequest<Level>(entityName: "Level")
        request.predicate = NSPredicate(format: "uuid == %@", uuid)
        var level: Level?
        moc.performAndWait({
            do{
                level = try moc.fetch(request).first
            }catch{
                fatalError("WAT")
            }
        })
        
        return level
    }
    
    fileprivate func levelInStructureWithName(_ structure: Structure, name: String, moc: NSManagedObjectContext) -> Level?{
        let request = NSFetchRequest<Level>(entityName: "Level")
        request.predicate = NSPredicate(format: "structure == %@ AND name == %@", structure, name)
        var level: Level?
        moc.performAndWait({
            do{
                level = try moc.fetch(request).first
            }catch{
                fatalError("WAT")
            }
        })
        
        return level
    }
    
    
    
    func mostRecentCount(fromDate date: Date, onLevel level: Level, usingContext context: NSManagedObjectContext) -> Count? {
        let request = NSFetchRequest<Count>(entityName: "Count")
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        request.predicate = NSPredicate(format: "(level == %@) AND (updatedAt <= %@)", [level, date])
        request.fetchLimit = 1
        
        var count: Count?
        context.performAndWait({
            do{
                count = try context.fetch(request).first
            } catch {
                NSLog("error")
            }
        })
        return count
    }
    
    /// Fetches `Count` objects with UIMOC, returns chronologically sorted list
    func countsOn(_ level: Level, since date: Date) -> [Count] {
        let context = DataManager.sharedInstance.managedObjectContext
        let request = NSFetchRequest<Count>(entityName: "Count")
        let chronoSort = NSSortDescriptor(key: "updatedAt", ascending: true)
        request.sortDescriptors = [chronoSort]
        request.predicate = NSPredicate(format: "(level == %@) AND (updatedAt >= %@)", level, date as CVarArg)
        
        var counts: [Count] = []
        context.performAndWait({
            do{
                counts = try context.fetch(request)
            } catch {
                NSLog("error with fetch")
            }
        })
        
        return counts
    }
    
    func fetchAllStructures() -> [Structure] {
        let context = managedObjectContext
        let request = NSFetchRequest<Structure>(entityName: "Structure")
        var structures: [Structure] = []
        context.performAndWait({
            do {
                structures = try context.fetch(request)
            } catch {
                NSLog("Fetch error")
            }
        })
        
        return structures
    }
    
    // MARK: - Object parsing from API
    
    fileprivate func process(_ structure: CPStructure, withContext context: NSManagedObjectContext?) {
        var moc: NSManagedObjectContext
        if let context = context {
            moc = context
        } else {
            moc = try! createPrivateQueueContext()
        }
        
        moc.perform({
            var s: Structure
            if let structure = self.structureWith(structure.uuid, moc: moc) {
                s = structure
            } else {
                s = NSEntityDescription.insertNewObject(forEntityName: "Structure", into: moc) as! Structure
                let loc = NSEntityDescription.insertNewObject(forEntityName: "Location", into: moc) as! Location
                s.location = loc
                s.uuid = structure.uuid
                NSLog("New Structure")
            }
            
            s.location?.lat = structure.lat as NSNumber?
            s.location?.long = structure.long as NSNumber?
            s.name = structure.name
            
            try! moc.save()
        })
    }
    
    fileprivate func process(_ level: CPLevel, inStructure structure: Structure, withContext context: NSManagedObjectContext?) {
        var moc: NSManagedObjectContext
        if let context = context {
            moc = context
        } else {
            moc = try! createPrivateQueueContext()
        }
        
        moc.perform({
            var l: Level
            if let level = self.levelWith(level.uuid, moc: moc){
                l = level
            }else{
                l = NSEntityDescription.insertNewObject(forEntityName: "Level", into: moc) as! Level
                l.structure = structure
                l.uuid = level.uuid
                NSLog("New Level")
            }
            
            l.name = level.name
            l.capacity = level.capacity as NSNumber?
            l.currentCount = level.currentCount as NSNumber?
            try! moc.save()
        })
    }
    
    fileprivate func process(_ counts: [CPCount], onLevel level: Level, withContext context: NSManagedObjectContext?, completion: (([Count]) -> ())?){
        var moc: NSManagedObjectContext
        if let context = context {
            moc = context
        } else {
            moc = try! createPrivateQueueContext()
        }
        var countArray: [Count] = []
        moc.perform({
            for count in counts{
                let c = NSEntityDescription.insertNewObject(forEntityName: "Count", into: moc) as! Count
                c.availableSpaces = count.count as NSNumber?
                c.updatedAt = count.timestamp
                c.level = moc.object(with: level.objectID) as? Level
                c.uuid = count.uuid
                countArray.append(c)
            }
            try! moc.save()
            completion?(countArray)
        })
    }
    
    func update(_ level: Level, startDate start: Date?, endDate end: Date?, completion: (([Count]) -> ())?){
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
    
    // MARK: - Push Notifications
    
    func fetchNotificationLevels(completion: @escaping ([Level]) -> () ) {
        let request = NSFetchRequest<Level>(entityName: "Level")
        request.predicate = NSPredicate(format: "notificationsEnabled == %d", 1)
        if let context = try? createPrivateQueueContext() {
            context.perform {
                if let results = try? context.fetch(request) {
                    completion(results)
                } else {
                    NSLog("Failed to fetch levels")
                }
            }
        } else {
            NSLog("Failed to create private context")
        }
    }
    
    func subscribeToAllLevels() {
        let backgroundContext = try! createPrivateQueueContext()
        let request = NSFetchRequest<Level>(entityName: "Level")
        
        backgroundContext.perform({
            do{
                let levels = try backgroundContext.fetch(request)
                for level in levels {
                    NotificationService.sharedInstance.enableNotifications(for: level)
                }
                
            } catch {
                NSLog("Error fetching levels for subscription")
            }
        })
    }
    
    func disableAllNotifications() {
        let backgroundContext = try! createPrivateQueueContext()
        let request = NSFetchRequest<Level>(entityName: "Level")
        backgroundContext.perform({
            do{
                let levels = try backgroundContext.fetch(request)
                for level in levels {
                    level.notificationsEnabled = false
                }
                
                try backgroundContext.save()
            } catch {
                NSLog("Error fetching levels for subscription")
            }
        })
    }
    
    func update(notificationsEnabled enabled: Bool, forUUIDs uuids: [String], withCompletion completion: @escaping ()->()) {
        let backgroundContext = try? createPrivateQueueContext()
        backgroundContext?.perform({
            let request = NSFetchRequest<Level>(entityName: "Level")
            
            // Enable notifications for objects in uuids
            request.predicate = NSPredicate(format: "uuid IN %@", uuids)
            if let levels = try? backgroundContext?.fetch(request){
                levels?.forEach({ $0.notificationsEnabled = true })
            }
            
            
            
            // Disable notifications for the rest
            request.predicate = NSPredicate(format: "NOT (uuid IN %@)", uuids)
            if let levels = try? backgroundContext?.fetch(request){
                levels?.forEach({ $0.notificationsEnabled = false })
            }
            
            _ = try? backgroundContext?.save()
            completion()
        })
    }
    
    func update(notificationsEnabled enabled: Bool, forLevel level: Level) {
        let backgroundContext = try? createPrivateQueueContext()
        backgroundContext?.perform({
            let level = backgroundContext?.object(with: level.objectID) as! Level
            level.notificationsEnabled = enabled as NSNumber?
            _ = try? backgroundContext?.save()
        })
    }

    // MARK: - Heartbeat
    @objc
    fileprivate func timerUpdateCounts(){
        updateCounts(.sinceLast)
    }

    /// TODO: Re-implement using above new functions
    func updateCounts(_ updateType: UpdateType, withCompletion completion: ((Bool) -> ())? = nil){
        let backgroundContext = try! createPrivateQueueContext()
        var sinceDate: Date? = nil
        
        if updateType == .sinceLast{
            let request = NSFetchRequest<Count>(entityName: "Count")
            request.fetchLimit = 1
            let dateSort = NSSortDescriptor(key: "updatedAt", ascending: false)
            request.sortDescriptors = [dateSort]
            
            backgroundContext.performAndWait({
                if let date = (try? backgroundContext.fetch(request))?.first?.updatedAt {
                    sinceDate = date
                    NSLog("Getting counts since \(date)")
                } else {
                    NSLog("Attempted to catch up without any data. Getting most recent instead.")
                }
            })
        }
        NSLog("Generating report...")
        api.generateReport(updateType, sinceDate: sinceDate, withBlock: {report in
            
            guard let report = report else{
                NSLog("Report generation failed")
                completion?(false)
                return
            }
            
            backgroundContext.perform({
                for structure in report.structures{
                    var s: Structure
                    
                    if let structure = self.structureWith(structure.uuid, moc: backgroundContext){
                        s = structure
                    }else{
                        s = NSEntityDescription.insertNewObject(forEntityName: "Structure", into: backgroundContext) as! Structure
                        let loc = NSEntityDescription.insertNewObject(forEntityName: "Location", into: backgroundContext) as! Location
                        loc.lat = structure.lat as NSNumber?
                        loc.long = structure.long as NSNumber?
                        
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
                            l = NSEntityDescription.insertNewObject(forEntityName: "Level", into: backgroundContext) as! Level
                            l.structure = s
                            l.uuid = level.uuid
                            NSLog("New Level")
                        }
                        
                        l.name = level.name
                        l.capacity = level.capacity as NSNumber?
                        l.currentCount = level.currentCount as NSNumber?
                        
                        var latestCount: CPCount? = nil
                        
                        for count in level.counts{
                            
                            if latestCount == nil || latestCount?.timestamp?.compare(count.timestamp!) == ComparisonResult.orderedAscending{
                                latestCount = count
                            }
                            
                            let c = NSEntityDescription.insertNewObject(forEntityName: "Count", into: backgroundContext) as! Count
                            c.availableSpaces = count.count as NSNumber?
                            c.updatedAt = count.timestamp
                            c.level = l
                            c.uuid = count.uuid
                        }
                        if let c = latestCount{
                            l.updatedAt = c.timestamp
                        }
                    }
                }
                try? backgroundContext.save()
                completion?(true)
            })
        })
        
    }
}
