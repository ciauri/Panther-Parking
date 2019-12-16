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
    func generateReport(_ updateType: UpdateType, sinceDate: Date?, withBlock completion: @escaping ((CPReport?) -> Void))
    func fetchCounts(fromLevelWithUUID uuid: String, starting startDate: Date?, ending endDate: Date?, completion: @escaping ([CPCount]?, NSError?) -> ())
    func subscribeTo(_ entity: ParkingEntity, withUUID uuid: String?, predicate: NSPredicate, onActions action: RemoteAction, notificationText text: String, completion: @escaping (Bool)->())
    func unsubscribeFrom(_ entity: ParkingEntity, withUUID uuid: String?, predicate: NSPredicate, onActions action: RemoteAction, completion: @escaping (Bool)->())
    func unsubscribeFromAll(_ completion: @escaping ()->())
    func forceUnsubscribeFromAll(_ completion: @escaping ()->())
    func fetchSubscriptions(_ completion: @escaping (_ uuids: [String]) -> ())
}

enum RemoteAction:Int {
    case update = 2
    case delete = 4
    case add = 1
    case once = 8
    
    var description: String {
        switch self{
        case .update:
            return "UPDATE"
        case .delete:
            return "DELETE"
        case .add:
            return "ADD"
        case .once:
            return "ONCE"
        }
    }
}

enum ParkingEntity {
    case structure
    case level
    case count
    
    var cloudKitName: String {
        switch self{
        case .structure:
            return "ParkingStructure"
        case .level:
            return "ParkingLevel"
        case .count:
            return "ParkingCount"
        }
    }
}
