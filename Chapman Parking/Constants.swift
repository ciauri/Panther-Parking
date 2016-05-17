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
        static let defaultCenter = CLLocationCoordinate2DMake(33.793379, -117.853099)
        static let defaultRegion = MKCoordinateRegion(center: defaultCenter, span: MKCoordinateSpanMake(0.0045, 0.0045))
    }
    
    struct Colors{
        static let chartColors: [UIColor] = [UIColor.blueColor(), UIColor.redColor(), UIColor.whiteColor(), UIColor.greenColor(), UIColor.grayColor(), UIColor.brownColor()]
    }
    
}
