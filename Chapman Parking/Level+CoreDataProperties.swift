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
    @NSManaged var enabled: NSNumber?
    @NSManaged var capacity: NSNumber?
    @NSManaged var currentCount: NSNumber?
    @NSManaged var structure: Structure?
    @NSManaged var counts: NSSet?
    @NSManaged var updatedAt: Date?
    @NSManaged var notificationsEnabled: NSNumber?

    var percentFull: String {
        guard let capacity = capacity,
            let currentCount = currentCount else {
                return ""
        }
        return FormatterUtility.shared.percentFormatter.string(from: NSNumber(floatLiteral:(Double(truncating: capacity)-Double(truncating: currentCount))/Double(truncating: capacity))) ?? "0"
    }

}
