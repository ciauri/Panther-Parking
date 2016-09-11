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
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "cogs"), style: .plain, target: self, action: #selector(openSettings))
        }
    }
    @IBOutlet weak var listBarItem: UIBarButtonItem! {
        didSet{
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "list"), style: .plain, target: self, action: #selector(flipToList))
        }
    }
    
    lazy var frcDelegate = GenericFetchedResultsControllerDelegate()
    lazy var frc: NSFetchedResultsController<Structure> = self.initFetchedResultsController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addStructuresToMap()

        let pantherLogo = UIImageView(image: UIImage(named: "panther"))
        pantherLogo.contentMode = .scaleAspectFit
        navigationItem.titleView = pantherLogo
        
    }

    
    fileprivate func freezeMap() {
        mapView.setRegion(Constants.Locations.defaultRegion, animated: false)
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isRotateEnabled = false
        mapView.showsTraffic = true
        mapView.showsScale = true
        mapView.showsCompass = true
        mapView.showsBuildings = true
    }
    
    func flipToList(){
        performSegue(withIdentifier: "flip", sender: self)
    }
    
    func openSettings(){
        performSegue(withIdentifier: "settings", sender: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func addStructuresToMap(){
        let context = DataManager.sharedInstance.managedObjectContext
        
        context.perform({
            do{
                try self.frc.performFetch()
                
                if let structures = self.frc.fetchedObjects {
                    for s in structures {
                        self.mapView.addAnnotation(s)
                    }
                }
                
            }catch{
                NSLog("issues and tissues")
            }
        })
 
        
    }
    
    fileprivate func initFetchedResultsController() -> NSFetchedResultsController<Structure>{
        let context = DataManager.sharedInstance.managedObjectContext
        let request = NSFetchRequest<Structure>(entityName: "Structure")
        let sort = NSSortDescriptor(key: "name", ascending: false)
        request.sortDescriptors = [sort]
        let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        frcDelegate.mapView = mapView
        frc.delegate = frcDelegate

        return frc
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier!{
        case "annotation":
            let annotation = mapView.selectedAnnotations.first
            let destinationVC = segue.destination as! ParkingViewController
            destinationVC.structure = annotation as? Structure
        default:
            break
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    @IBAction func prepareForSettingsDoneSegue(_ sender: UIStoryboardSegue) {
        NSLog("Settings dismissed")
    }

}


extension MapViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? Structure{
            var view: MKPinAnnotationView
            let reuseId = "pin"
            
            if let reusedView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView{
                reusedView.annotation = annotation
                view = reusedView
            }else{
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier:reuseId)
                view.canShowCallout = true
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                view.pinTintColor = UIColor.temperatureColor(fromPercentCompletion: Float(annotation.capacity-annotation.currentCount)/Float(annotation.capacity))
                view.animatesDrop = true
            }
            return view
        }else{
            return nil
        }
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        performSegue(withIdentifier: "annotation", sender: self)
    }
    
}
