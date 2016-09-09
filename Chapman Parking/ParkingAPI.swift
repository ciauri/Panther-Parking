//
//  ParkingAPI.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/12/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation


protocol ParkingAPI: class{
    static var sharedInstance: ParkingAPI {get}
    func generateReport(updateType: UpdateType, sinceDate: NSDate?, withBlock: (CPReport? -> Void))
    func fetchCounts(fromLevelWithUUID uuid: String, starting startDate: NSDate?, ending endDate: NSDate?, completion: ([CKCount]?, NSError?) -> ())
    func subscribeTo(entity: ParkingEntity, withUUID uuid: String?, predicate: NSPredicate, onActions action: RemoteAction, notificationText text: String, completion: (Bool)->())
    func unsubscribeFrom(entity: ParkingEntity, withUUID uuid: String?, predicate: NSPredicate, onActions action: RemoteAction, completion: (Bool)->())
    func unsubscribeFromAll(completion: ()->())
    func forceUnsubscribeFromAll(completion: ()->())
    func fetchSubscriptions(completion: (uuids: [String]) -> ())
}

enum RemoteAction:Int {
    case Update = 2
    case Delete = 4
    case Add = 1
    case Once = 8
    
    var description: String {
        switch self{
        case .Update:
            return "UPDATE"
        case .Delete:
            return "DELETE"
        case .Add:
            return "ADD"
        case .Once:
            return "ONCE"
        }
    }
}

enum ParkingEntity {
    case Structure
    case Level
    case Count
    
    var cloudKitName: String {
        switch self{
        case .Structure:
            return "ParkingStructure"
        case .Level:
            return "ParkingLevel"
        case .Count:
            return "ParkingCount"
        }
    }
}