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
        let entity = NSEntityDescription.entity(forEntityName: "Structure", in: context)!
        self.init(entity: entity, insertInto: context)
        name = "Name" <~~ json

    }
    



}
