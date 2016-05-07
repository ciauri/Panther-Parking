//
//  Count+CoreDataProperties.swift
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

extension Count {

    @NSManaged var availableSpaces: NSNumber?
    @NSManaged var updatedAt: NSDate?
    @NSManaged var level: Level?

}
