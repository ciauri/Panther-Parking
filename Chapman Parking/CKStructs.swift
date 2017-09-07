//
//  CKStructs.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/12/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation
import CoreLocation

protocol CKObject{
    var ckID: String {get set}
}

struct CKStructure: CPStructure{
    var uuid: String
    var name: String?
    var levels: [CPLevel]
    var lat: Double?
    var long: Double?
}

struct CKLevel: CPLevel{
    var uuid: String
    var name: String?
    var capacity: Int?
    var counts: [CPCount]
    var currentCount: Int
    var enabled: Bool
}

struct CKCount: CPCount{
    var uuid: String
    var count: Int?
    var timestamp: Date?
}

struct CKReport:CPReport{
    var structures: [CPStructure]
}



//struct JSONReport: Decodable{
//    let structures: [JSONStructure]
//    
//    init?(json: JSON) {
//        structures = [JSONStructure].fromJSONArray(("structures" <~~ json)!)
//    }
//}
