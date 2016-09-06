//
//  Constants.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/4/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation
import MapKit
import UIKit

struct Constants{
    struct URLs{
        static let chapmanParkingURL = NSURL(string: "https://webfarm.chapman.edu/parkingservice/parkingservice/counts")!
        static let stephenParkingURL = NSURL(string: "http://stephenciauri.com/parking/counts")!
    }
    
    struct Locations{
        static let defaultCenter = CLLocationCoordinate2DMake(33.793544863688943, -117.8533288587884)
        static let defaultRegion = MKCoordinateRegion(center: defaultCenter, span: MKCoordinateSpanMake(0.013913792613969633, 0.010634114112036741))
    }
    
    struct Colors{
        static let chartColors: [UIColor] = [UIColor.blueColor(), UIColor.redColor(), UIColor.whiteColor(), UIColor.greenColor(), UIColor.grayColor(), UIColor.brownColor()]
    }
    
    struct DefaultsKeys{
        static let cumulativeLine = "showCumulativeLine"
        static let notificationsEnabled = "notificationsEnabled"
        static let structuresOnly = "structuresOnly"

    }
    
}
