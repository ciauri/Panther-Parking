//
//  JSONStructs.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/4/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation
import Gloss

struct JSONReport: Decodable, CPReport{
    let structures: [CPStructure]
    
    init?(json: JSON) {
        structures = [JSONStructure].fromJSONArray(("structures" <~~ json)!).map({$0 as CPStructure})
    }
}

struct JSONStructure: Decodable, CPStructure{
    
    let name: String?
    let levels: [CPLevel]
    let lat: Double?
    let long: Double?
    
    
    init?(json: JSON) {
        name = "name" <~~ json
        let levelsFromJSON = [JSONLevel].fromJSONArray(("levels" <~~ json)!)
        levels = levelsFromJSON.map({$0 as CPLevel})
        
        // Gloss sucks
        lat = Double(json["lat"] as! String)!
        long = Double(json["long"] as! String)!
    }
    
}

struct JSONLevel: Decodable, CPLevel{
    
    let name: String?
    let capacity: Int?
    let counts: [CPCount]
    let currentCount: Int
    
    init?(json: JSON) {
        name = "name" <~~ json
        capacity = "capacity" <~~ json
        let countsFromJSON = [JSONCount].fromJSONArray(("counts" <~~ json)!)
        let cpcounts = countsFromJSON.map({$0 as CPCount})
        counts = cpcounts
        currentCount = 0

    }
    
    
}

struct JSONCount: Decodable, CPCount{
    let count: Int?
    let timestamp: NSDate?
    
    init?(json: JSON){
        count = "count" <~~ json
        timestamp = NSDate.dateFromISOString(("timestamp" <~~ json)!)
    }
    
}
