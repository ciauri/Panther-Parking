//
//  ParkingAPI.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/12/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation


protocol ParkingAPI{
    static var sharedInstance: ParkingAPI {get}
    func generateReport(updateType: UpdateType, sinceDate: NSDate?, withBlock: (CPReport -> Void))
    func fetchCounts(fromLevelWithUUID uuid: String, starting startDate: NSDate?, ending endDate: NSDate?, completion: ([CKCount]?, NSError?) -> ())
    
}