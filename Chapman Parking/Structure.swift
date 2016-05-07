//
//  Structure.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/4/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation
import CoreData
import Gloss
import MapKit

class Structure: NSManagedObject{

// Insert code here to add functionality to your managed object subclass
    
    convenience init(json: JSON, insertIntoManagedObjectContext context: NSManagedObjectContext!){
        let entity = NSEntityDescription.entityForName("Structure", inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)
        name = "Name" <~~ json

    }
    



}
