//
//  StructureMarkerAnnotationView.swift
//  PantherPark
//
//  Created by stephenciauri on 9/30/17.
//  Copyright © 2017 Stephen Ciauri. All rights reserved.
//

import UIKit
import MapKit

class StructureMarkerAnnotationView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            if let structure = newValue as? Structure {
                markerTintColor = UIColor.temperatureColor(fromPercentCompletion: Float(structure.capacity-structure.currentCount)/Float(structure.capacity))
                glyphImage = #imageLiteral(resourceName: "car")
                glyphTintColor = .white
                canShowCallout = true
                titleVisibility = .visible
                rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
        }
    }

}
