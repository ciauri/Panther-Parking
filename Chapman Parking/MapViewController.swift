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
        if self.traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: self.view)
        }

        let pantherLogo = UIImageView(image: UIImage(named: "panther"))
        pantherLogo.contentMode = .scaleAspectFit
        navigationItem.titleView = pantherLogo
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        freezeMap()
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil, completion: { _ in
            self.mapView.setRegion(Constants.Locations.defaultRegion, animated: false)
        })
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
        mapView.mapType = .mutedStandard
        mapView.register(StructureMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
    }
    
    @objc func flipToList(){
        performSegue(withIdentifier: "flip", sender: self)
    }
    
    @objc func openSettings(){
        performSegue(withIdentifier: "settings", sender: self)
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
        frcDelegate.delegate = self
        frc.delegate = frcDelegate

        return frc
    }
    

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier!{
        case "annotation":
            if let annotation = sender as? Structure {
                let destinationVC = segue.destination as! ParkingViewController
                destinationVC.structure = annotation
            }
        default:
            break
        }
    }
    
    @IBAction func prepareForSettingsDoneSegue(_ sender: UIStoryboardSegue) {
        NSLog("Settings dismissed")
    }
    
    func annotation(forPoint location: CGPoint) -> MKAnnotation? {
        let convertedPoint = mapView.convert(location, toCoordinateFrom: view)
        let mapPoint = MKMapPointForCoordinate(convertedPoint)
        let generalArea = MKMapRect(origin: mapPoint, size: mapView.visibleMapRect.size)
        let annotations = mapView.annotations(in: generalArea)
        if let annotation = annotations.first as? MKAnnotation {
            return annotation
        } else {
            return nil
        }
    }

}


extension MapViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        performSegue(withIdentifier: "annotation", sender: view.annotation)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleView = MKCircleRenderer(circle: overlay as! MKCircle)
        circleView.strokeColor = .red
        circleView.fillColor = UIColor.red.withAlphaComponent(0.4)
        return circleView
    }
}

extension MapViewController: GenericFRCDelegate {
    func controllerDidChangeContent() {
        let currentAnnotations = mapView.annotations
        mapView.removeAnnotations(currentAnnotations)
        mapView.addAnnotations(currentAnnotations)
    }
}



extension MapViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let annotation = annotation(forPoint: location) as? Structure,
            let viewController = storyboard?.instantiateViewController(withIdentifier: "ParkingViewController") as? ParkingViewController {
            viewController.structure = annotation
            return viewController
        } else {
            return nil
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }
}
