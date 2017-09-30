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
        return levels?.first(where: {$0.name! == "All Levels"})?.capacity as? Int ?? 0
    }
    
    var currentCount: Int{
        var count = 0
        for level in levels! where level.name != "All Levels" && level.enabled?.boolValue ?? true {
            let level = level
            count += Int(truncating: level.currentCount!)
        }
        
        return count
        
    }
    

}

extension Structure: MKAnnotation{
    var title:String? {
        return name
    }
    
    var subtitle: String?{
        let percent = FormatterUtility.shared.percentFormatter.string(from: NSNumber(floatLiteral:(Double(capacity)-Double(currentCount))/Double(capacity)))!
        return "\(percent) full"
    }
    
    var coordinate: CLLocationCoordinate2D{
        if let location = location, let lat = location.lat, let long = location.long{
            return CLLocationCoordinate2DMake(Double(truncating: lat), Double(truncating: long))
        }else{
            return CLLocationCoordinate2DMake(0, 0)
        }
    }
}
