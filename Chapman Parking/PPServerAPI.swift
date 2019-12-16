//
//  PPServerAPI.swift
//  PantherPark
//
//  Created by Stephen Ciauri on 12/14/19.
//  Copyright © 2019 Stephen Ciauri. All rights reserved.
//

import Foundation

class PPServerAPI: ParkingAPI {
    static let sharedInstance: ParkingAPI = PPServerAPI()
    
    func generateReport(_ updateType: UpdateType, sinceDate: Date?, withBlock completion: @escaping ((CPReport?) -> Void)) {
        <#code#>
    }
    
    func fetchCounts(fromLevelWithUUID uuid: String, starting startDate: Date?, ending endDate: Date?, completion: @escaping ([CKCount]?, NSError?) -> ()) {
        <#code#>
    }
    
    func subscribeTo(_ entity: ParkingEntity, withUUID uuid: String?, predicate: NSPredicate, onActions action: RemoteAction, notificationText text: String, completion: @escaping (Bool) -> ()) {
        <#code#>
    }
    
    func unsubscribeFrom(_ entity: ParkingEntity, withUUID uuid: String?, predicate: NSPredicate, onActions action: RemoteAction, completion: @escaping (Bool) -> ()) {
        <#code#>
    }
    
    func unsubscribeFromAll(_ completion: @escaping () -> ()) {
        <#code#>
    }
    
    func forceUnsubscribeFromAll(_ completion: @escaping () -> ()) {
        <#code#>
    }
    
    func fetchSubscriptions(_ completion: @escaping ([String]) -> ()) {
        <#code#>
    }
    
    
}
