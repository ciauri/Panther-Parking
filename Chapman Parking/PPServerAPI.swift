//
//  PPServerAPI.swift
//  PantherPark
//
//  Created by Stephen Ciauri on 12/14/19.
//  Copyright © 2019 Stephen Ciauri. All rights reserved.
//

import Foundation
import PPKit

class PPServerAPI: ParkingAPI {
    static let sharedInstance: ParkingAPI = PPServerAPI()
    
    func generateReport(_ updateType: UpdateType, sinceDate: Date?, withBlock completion: @escaping ((CPReport?) -> Void)) {
        PPKitServer(with: URL(string: "http://localhost:8080")!).fetchStructures { (result) in
            switch result {
            case .success(let structures):
                completion(PPKReport(structs: structures))
            case .failure:
                break
            }
        }
    }
    
    func fetchCounts(fromLevelWithUUID uuid: String, starting startDate: Date?, ending endDate: Date?, completion: @escaping ([CPCount]?, NSError?) -> ()) {
        
    }
    
    func subscribeTo(_ entity: ParkingEntity, withUUID uuid: String?, predicate: NSPredicate, onActions action: RemoteAction, notificationText text: String, completion: @escaping (Bool) -> ()) {
        
    }
    
    func unsubscribeFrom(_ entity: ParkingEntity, withUUID uuid: String?, predicate: NSPredicate, onActions action: RemoteAction, completion: @escaping (Bool) -> ()) {
        
    }
    
    func unsubscribeFromAll(_ completion: @escaping () -> ()) {
        
    }
    
    func forceUnsubscribeFromAll(_ completion: @escaping () -> ()) {
        
    }
    
    func fetchSubscriptions(_ completion: @escaping ([String]) -> ()) {
        
    }
    
    struct PPKReport: CPReport {
        var structures: [CPStructure] {
            return structs.map({ PPStructure(ppkStructure: $0) })
        }
        
        let structs: [PPKStructure]
    }
}

struct PPStructure: CPStructure {
    let ppkStructure: PPKStructure
    
    var uuid: String {
        return ppkStructure.id
    }
    
    var name: String {
        return ppkStructure.name
    }
    
    var levels: [CPLevel] {
        return ppkStructure.levels.map({ return PPLevel(ppkLevel: $0, lastUpdated: ppkStructure.lastUpdated) })
    }
    
    var lat: Double? {
        return ppkStructure.latitude
    }
    
    var long: Double? {
        return ppkStructure.longitude
    }
}

struct PPLevel: CPLevel {
    let ppkLevel: PPKLevel
    
    let lastUpdated: Date
    
    var uuid: String {
        return ppkLevel.id
    }
    
    var name: String {
        return ppkLevel.name
    }
    
    var capacity: Int {
        return ppkLevel.capacity
    }
    
    var counts: [CPCount] {
        return [PPCount(ppkCount: .init(levelID: uuid, spots: currentCount, timestamp: lastUpdated))]
    }
    
    var currentCount: Int {
        return ppkLevel.currentCount
    }
    
    var enabled: Bool {
        return true
    }
}

struct PPCount: CPCount {
    let ppkCount: PPKSpotCount
    
    var uuid: String {
        return ppkCount.id.uuidString
    }
    
    var count: Int? {
        return ppkCount.availableSpots
    }
    
    var timestamp: Date? {
        return ppkCount.timestamp
    }
}
