//
//  CPStruct.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/13/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation

//protocol CPReport{
//    var structures
//}

protocol CPReport{
    var structures: [CPStructure] {get}
}

protocol CPStructure{
    var uuid: String {get}
    var name: String? {get}
    var levels: [CPLevel] {get}
    var lat: Double? {get}
    var long: Double? {get}
}

protocol CPLevel{
    var uuid: String {get}
    var name: String? {get}
    var capacity: Int? {get}
    var counts: [CPCount] {get}
    var currentCount: Int {get}
    var enabled: Bool {get}
}

protocol CPCount{
    var uuid: String {get}
    var count: Int? {get}
    var timestamp: Date? {get}
}
