//
//  LocationService.swift
//  PantherPark
//
//  Created by Stephen Ciauri on 9/5/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation
import CoreLocation

// TODO: Think about this. I can't blanket disable push notifications. Maybe I can unregister for each subscription, but not remove from list of subscriptions so that I can re-use them..
class LocationService: NSObject{
    static let sharedInstance = LocationService()
    
    private let manager = CLLocationManager()
    
    var eventHandlerDelegate: GeofenceEventHandler?
    
    var geofencingIsSupported: Bool {
        return CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
    }
    var adequateLocationPermissionsEnabled: Bool {
        return CLLocationManager.authorizationStatus() == .authorizedAlways
    }
    
    var chapmanRegion: CLCircularRegion {
        let circle = CLCircularRegion(center: Constants.Locations.defaultCenter, radius: 500, identifier: "ChapmanUniversity")
        circle.notifyOnExit = true
        circle.notifyOnEntry = true
        return circle
    }
    
    enum LocationState {
        case atChapman
        case notAtChapman
        case unknown
    }
    
    var currentLocation : LocationState = .unknown
    
    fileprivate override init() {
        super.init()
        manager.delegate = self
        manager.requestAlwaysAuthorization()
    }
    
    
    internal func startMonitoring() {
        if !geofencingIsSupported {
            NSLog("Geofencing is not supported on this device")
        } else if !adequateLocationPermissionsEnabled {
            NSLog("Location services aren't enabled")
        } else if manager.monitoredRegions.count > 0 {
            NSLog("Already monitoring Chapman")
        } else {
            registerChapmanGeofence()
        }
    }
    
    internal func stopMonitoring() {
        manager.stopMonitoring(for: chapmanRegion)
    }
    
    
    fileprivate func registerChapmanGeofence() {
        manager.startMonitoring(for: chapmanRegion)
    }
}

// MARK: - CLLocationMananger Delegate methods
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        NSLog("Unable to monitor region \(region) due to error \(error)")
        currentLocation = .unknown
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("General location manager failure: \(error))")
        currentLocation = .unknown
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        NSLog("Disabling push notifications")
        currentLocation = .atChapman
        eventHandlerDelegate?.didEnterRegion()
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        NSLog("Enabling push notifications")
        currentLocation = .notAtChapman
        eventHandlerDelegate?.didExitRegion()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status{
        case .authorizedAlways, .authorizedWhenInUse:
            startMonitoring()
        default:
            stopMonitoring()
            currentLocation = .unknown
        }
    }
}

protocol GeofenceEventHandler: class {
    func didExitRegion()
    func didEnterRegion()
}
