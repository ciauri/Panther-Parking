//
//  Level+CoreDataProperties.swift
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

extension Level {

    @NSManaged var name: String?
    @NSManaged var uuid: String?
    @NSManaged var capacity: NSNumber?
    @NSManaged var currentCount: NSNumber?
    @NSManaged var structure: Structure?
    @NSManaged var counts: NSSet?
    @NSManaged var updatedAt: NSDate?
    
//    var currentCount: Int{
//        get{
//            let sort = NSSortDescriptor(key: "updatedAt", ascending: false)
//            let arr: Array = (counts?.sortedArrayUsingDescriptors([sort]))!
//            if let count = (arr.first as? Count)?.availableSpaces{
//                return Int(count)
//            }else{
//                return 0
//            }
//        }
//    }
//    
//    var updatedAt: NSDate{
//        get{
//            let sort = NSSortDescriptor(key: "updatedAt", ascending: false)
//            let arr: Array = (counts?.sortedArrayUsingDescriptors([sort]))!
//            return (arr.first as! Count).updatedAt!
//        }
//    }

}
