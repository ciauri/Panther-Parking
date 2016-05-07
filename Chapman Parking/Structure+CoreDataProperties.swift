//
//  Structure+CoreDataProperties.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/4/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Structure {

    @NSManaged var name: String?
    @NSManaged var levels: NSSet?
    @NSManaged var location: Location?
    
    var capacity: Int{
        get{
            var cap = 0
            for level in levels! as NSSet{
                let level = level as! Level
                cap += Int(level.capacity!)
            }
            return cap
        }
        
    }

}
