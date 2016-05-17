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

    @IBOutlet var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "list"), style: .Plain, target: self, action: #selector(flipToList))
        mapView.setRegion(Constants.Locations.defaultRegion, animated: false)
        addStructuresToMap()
        

        // Do any additional setup after loading the view.
    }
    
    func flipToList(){
        performSegueWithIdentifier("flip", sender: self)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func addStructuresToMap(){
        let context = DataManager.sharedInstance.managedObjectContext
        let request = NSFetchRequest(entityName: "Structure")
        
        context.performBlock({
            do{
                let results = try context.executeFetchRequest(request)
                
                self.mapView.addAnnotations(results as! [Structure])

            }
            catch{
                
            }
        })
        
        
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

}

extension MapViewController: MKMapViewDelegate{
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Structure{
            var view: MKAnnotationView
            let reuseId = "pin"
            
            if let reusedView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView{
                reusedView.annotation = annotation
                view = reusedView
            }else{
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier:reuseId)
                view.canShowCallout = true
                view.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
                
                //Only works in iOS 8+
                /*
                 view.animatesDrop = true
                 */
            }
            return view
        }else{
            return nil
        }
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        performSegueWithIdentifier("annotation", sender: self)
    }
    

//    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//        let region = mapView.region
//    }
    
}
