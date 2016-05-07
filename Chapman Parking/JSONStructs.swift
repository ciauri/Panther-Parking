//
//  JSONStructs.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/4/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation
import Gloss

struct JSONReport: Decodable{
    let structures: [JSONStructure]
    
    init?(json: JSON) {
        structures = [JSONStructure].fromJSONArray(("structures" <~~ json)!)
    }
}

struct JSONStructure: Decodable{
    
    let name: String?
    let levels: [JSONLevel]
    let lat: Double?
    let long: Double?
    
    
    init?(json: JSON) {
        name = "name" <~~ json
        levels = [JSONLevel].fromJSONArray(("levels" <~~ json)!)
        lat = "lat" <~~ json
        long = "long" <~~ json
    }
    
}

struct JSONLevel: Decodable{
    
    let name: String?
    let capacity: Int?
    let counts: [JSONCount]
    
    init?(json: JSON) {
        name = "name" <~~ json
        capacity = "capacity" <~~ json
        counts = [JSONCount].fromJSONArray(("counts" <~~ json)!)
    }
    
}

struct JSONCount: Decodable{
    let count: Int?
    let timestamp: NSDate?
    
    init?(json: JSON){
        count = "count" <~~ json
        timestamp = NSDate.dateFromISOString(("timestamp" <~~ json)!)
    }
}