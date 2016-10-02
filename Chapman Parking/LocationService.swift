//
//  LocationService.swift
//  PantherPark
//
//  Created by Stephen Ciauri on 9/5/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class LocationService: NSObject{
    static let sharedInstance = LocationService()
    
    fileprivate let manager = CLLocationManager()
    fileprivate var geofencingIsSupported: Bool {
        return CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
    }
    fileprivate var adequateLocationPermissionsEnabled: Bool {
        return CLLocationManager.authorizationStatus() == .authorizedAlways
    }
    
    var eventHandlerDelegate: GeofenceEventHandler?

    var chapmanRegion: CLCircularRegion {
        let circle = CLCircularRegion(center: Constants.Locations.defaultCenter, radius: 500, identifier: "ChapmanUniversity")
        circle.notifyOnExit = true
        circle.notifyOnEntry = true
        return circle
    }
    
    var geolocationState: GeolocationState {
        if adequateLocationPermissionsEnabled && manager.monitoredRegions.count > 0 {
            return .enabled
        } else if !geofencingIsSupported {
            return .unsupported
        } else {
            return .disabled
        }
    }
    
    enum GeolocationState {
        case paused
        case enabled
        case disabled
        case unsupported
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
    
    /**
     Enables or disbles region monitoring
     
     - parameter on: Boolean indicating desired state
     - parameter sender: The view controller requesting permission. Will show failure alert on this view controller
     - returns: If true, desired state is successful. If false, desired state could not be reached
     */
    internal func setMonitoring(on: Bool, from sender: UIViewController? = nil, with completion: ((Bool)->())? = nil){
        if adequateLocationPermissionsEnabled && geofencingIsSupported {
            if on {
                startMonitoring()
            } else {
                stopMonitoring()
            }
            completion?(true)
        } else {
            if let viewController = sender {
                presentGeolocationRegistrationFailureAlert(on: viewController, for: geolocationState) {
                    completion?(false)
                }
            }
        }
    }
    
    fileprivate func presentGeolocationRegistrationFailureAlert(on viewController: UIViewController, for reason: GeolocationState, with completion: (()->())? = nil) {
        var errorBody: String
        var dismissText: String
        var settingsAction: UIAlertAction?

        
        switch reason {
        case .unsupported:
            errorBody = "Your device does not support Geolocation"
            dismissText = "Ok"
        case .disabled:
            errorBody = "Please enable location permissions in your device settings"
            settingsAction = UIAlertAction(title: "Settings",
                                               style: .cancel,
                                               handler: {_ in
                                                completion?()
                                                UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
            })
            dismissText = "Cancel"
        default:
            // Should not enter here with other states
            return
        }
        
        let alertController = UIAlertController(title: "Geolocation Error",
                                                message: errorBody,
                                                preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: dismissText,
                                         style: .destructive,
                                         handler: {_ in completion?()})
        alertController.addAction(cancelAction)
        if let settingsAction = settingsAction {
            alertController.addAction(settingsAction)
        }
        
        viewController.present(alertController,
                               animated: true,
                               completion: nil)
    }
    
    
    fileprivate func startMonitoring() {
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
    
    fileprivate func stopMonitoring() {
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
        currentLocation = .atChapman
        eventHandlerDelegate?.didEnterRegion()
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
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
    /// Called when device exits a monitored region
    func didExitRegion()
    
    /// Called when device enters a monitored region
    func didEnterRegion()
}
