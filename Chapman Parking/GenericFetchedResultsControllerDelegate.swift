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
    
    
    
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView?.beginUpdates()
        NSLog("Updating")
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type{
        case .Insert:
            tableView?.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            tableView?.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Move:
            //            tableView.moveSection(<#T##section: Int##Int#>, toSection: <#T##Int#>)
            break
        case .Update:
            break
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type{
        case .Insert:
            if let a = anObject as? MKAnnotation{
                mapView?.addAnnotation(a)
            }
            tableView?.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView?.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            if let a = anObject as? MKAnnotation{
                mapView?.removeAnnotation(a)
            }
        case .Update:
            if let indexPath = indexPath, cell = tableView?.cellForRowAtIndexPath(indexPath){
                delegate?.configureCell(cell, atIndexPath: indexPath)
            }
            if let a = anObject as? MKAnnotation{
                mapView?.removeAnnotation(a)
                mapView?.addAnnotation(a)
            }
        case .Move:
            if let a = anObject as? MKAnnotation{
                mapView?.removeAnnotation(a)
                mapView?.addAnnotation(a)
            }
//            tableView?.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
//            tableView?.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            if let indexPath = indexPath, cell = tableView?.cellForRowAtIndexPath(indexPath){
                delegate?.configureCell(cell, atIndexPath: indexPath)
                tableView?.moveRowAtIndexPath(indexPath, toIndexPath: newIndexPath!)
            }
        }
    }
    
    
    
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView?.endUpdates()
        NSLog("updated")
    }
    
    
}

protocol GenericFRCDelegate: class{
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath)
}