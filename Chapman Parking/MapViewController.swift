//
//  MapViewController.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/15/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {

    @IBOutlet var mapView: MKMapView! {
        didSet{
            freezeMap()
        }
    }
    @IBOutlet weak var settingsBarItem: UIBarButtonItem! {
        didSet{
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "cogs"), style: .Plain, target: self, action: #selector(openSettings))
        }
    }
    @IBOutlet weak var listBarItem: UIBarButtonItem! {
        didSet{
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "list"), style: .Plain, target: self, action: #selector(flipToList))
        }
    }
    
    lazy var frcDelegate = GenericFetchedResultsControllerDelegate()
    lazy var frc: NSFetchedResultsController = self.initFetchedResultsController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addStructuresToMap()
    }
    
    private func freezeMap() {
        mapView.setRegion(Constants.Locations.defaultRegion, animated: false)
        mapView.scrollEnabled = false
        mapView.zoomEnabled = false
        mapView.rotateEnabled = false
        mapView.showsTraffic = true
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.showsBuildings = true
    }
    
    func flipToList(){
        performSegueWithIdentifier("flip", sender: self)
    }
    
    func openSettings(){
        performSegueWithIdentifier("settings", sender: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func addStructuresToMap(){
        let context = DataManager.sharedInstance.managedObjectContext
        
        context.performBlock({
            do{
                try self.frc.performFetch()
                
                for s in self.frc.fetchedObjects as! [Structure]{
                    self.mapView.addAnnotation(s)
                }
            }catch{
                NSLog("issues and tissues")
            }
        })
 
        
    }
    
    private func initFetchedResultsController() -> NSFetchedResultsController{
        let context = DataManager.sharedInstance.managedObjectContext
        let request = NSFetchRequest(entityName: "Structure")
        let sort = NSSortDescriptor(key: "name", ascending: false)
        request.sortDescriptors = [sort]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        frcDelegate.mapView = mapView
        frc.delegate = frcDelegate

        return frc
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier!{
        case "annotation":
            let annotation = mapView.selectedAnnotations.first
            let destinationVC = segue.destinationViewController as! ParkingViewController
            destinationVC.structure = annotation as? Structure
        default:
            break
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    @IBAction func prepareForSettingsDoneSegue(sender: UIStoryboardSegue) {
        NSLog("Settings dismissed")
    }

}

extension MapViewController: MKMapViewDelegate{
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Structure{
            var view: MKPinAnnotationView
            let reuseId = "pin"
            
            if let reusedView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView{
                reusedView.annotation = annotation
                view = reusedView
            }else{
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier:reuseId)
                view.canShowCallout = true
                view.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
                view.pinTintColor = UIColor.temperatureColor(fromPercentCompletion: Float(annotation.capacity-annotation.currentCount)/Float(annotation.capacity))
                view.animatesDrop = true
            }
            return view
        }else{
            return nil
        }
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        performSegueWithIdentifier("annotation", sender: self)
    }
    
}
