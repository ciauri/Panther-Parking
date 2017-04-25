//
//  GenericFetchedResultsControllerDelegate.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/6/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MapKit

class GenericFetchedResultsControllerDelegate:NSObject, NSFetchedResultsControllerDelegate{
    
    var tableView: UITableView?
    var collectionView: UICollectionView?
    var mapView: MKMapView?
    weak var delegate: GenericFRCDelegate?
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type{
        case .insert:
            tableView?.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView?.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            //            tableView.moveSection(<#T##section: Int##Int#>, toSection: <#T##Int#>)
            break
        case .update:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type{
        case .insert:
            if let a = anObject as? MKAnnotation{
                mapView?.addAnnotation(a)
            }
            tableView?.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView?.deleteRows(at: [indexPath!], with: .fade)
            if let a = anObject as? MKAnnotation{
                mapView?.removeAnnotation(a)
            }
        // Update and Move
        default:
            if
                let annotation = anObject as? Structure,
                let annotationView = mapView?.view(for: annotation) as? MKPinAnnotationView{
                
                annotationView.pinTintColor = UIColor.temperatureColor(fromPercentCompletion: Float(annotation.capacity-annotation.currentCount)/Float(annotation.capacity))
            }
            if let indexPath = indexPath{
                tableView?.reloadRows(at: [indexPath], with: .automatic)
            }
        }
 
    }
    

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView?.endUpdates()
        delegate?.controllerDidChangeContent()
    }
    
    
}

protocol GenericFRCDelegate: class{
    func controllerDidChangeContent()
}
