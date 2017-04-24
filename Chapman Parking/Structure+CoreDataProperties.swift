//
//  Structure+CoreDataProperties.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/15/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData
import MapKit

extension Structure {

    @NSManaged var name: String?
    @NSManaged var uuid: String?
    @NSManaged var levels: Set<Level>?
    @NSManaged var location: Location?
    
    override var description: String {
        return name ?? "Unnamed Structure"
    }
    
    var capacity: Int{
        var cap = 0
        for level in levels! where level.name == "All Levels"{
            let level = level
            cap += Int(level.capacity!)
        }
        return cap
        
    }
    
    var currentCount: Int{
        var count = 0
        for level in levels! where level.name != "All Levels"{
            let level = level
            count += Int(level.currentCount!)
        }
        
        return count
        
    }
    

}

extension Structure: MKAnnotation{
    var title:String? {
        return name
    }
    
    var subtitle: String?{
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        
        NSLog("Count: \(currentCount) Cap: \(capacity)")
        let percent = formatter.string(from: NSNumber(floatLiteral:1.0-Double(currentCount)/Double(capacity)))!
        return "\(percent) full"
    }
    
    var coordinate: CLLocationCoordinate2D{
        if let location = location, let lat = location.lat, let long = location.long{
            return CLLocationCoordinate2DMake(Double(lat), Double(long))
        }else{
            return CLLocationCoordinate2DMake(0, 0)
        }
    }
}
