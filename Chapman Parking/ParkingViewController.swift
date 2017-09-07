//
//  ParkingViewController.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/5/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import UIKit
import CoreData

class ParkingViewController: UIViewController {
    @IBOutlet var parkingTableView: UITableView!
    
    lazy var frc: NSFetchedResultsController<Level> = self.initFRC()
    var frcDelegate = GenericFetchedResultsControllerDelegate()
    
    var structure: Structure?
    
    lazy fileprivate var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .long
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if structure == nil{
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "map"), style: .plain, target: self, action: #selector(flipToMap))
        }else{
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "clock"), style: .plain, target: self, action: #selector(segueToGraph))
        }
        fetchData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func flipToMap(){
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    func segueToGraph(){
        performSegue(withIdentifier: "chart", sender: self)
    }
    
    
     // MARK: - Navigation
    
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier!{
        case "chart":
            let destinationVC = segue.destination as! ChartViewController
            destinationVC.structure = structure
        default:
            break
        }
     }
    
}

extension ParkingViewController {
    fileprivate func initFRC() -> NSFetchedResultsController<Level>{
        
        let request = NSFetchRequest<Level>(entityName: "Level")
        let structureSort = NSSortDescriptor(key: "structure.name", ascending: true)
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        request.sortDescriptors = [structureSort, nameSort]
        
        if let s = structure {
            request.predicate = NSPredicate(format: "structure = %@ AND enabled = 1", s)
        } else {
            request.predicate = NSPredicate(format: "enabled = 1")
        }
        let controller = NSFetchedResultsController<Level>(fetchRequest: request, managedObjectContext: DataManager.sharedInstance.managedObjectContext, sectionNameKeyPath: "structure.name", cacheName: nil)
        frcDelegate.tableView = parkingTableView
        frcDelegate.delegate = self
        controller.delegate = frcDelegate
        return controller
    }
    
    fileprivate func fetchData(){
        DataManager.sharedInstance.managedObjectContext.perform({
            do{
                try self.frc.performFetch()
                self.parkingTableView.reloadData()
            } catch {
                fatalError("Failed to init FRC: \(error)")
            }
        })
    }
    
    
}

extension ParkingViewController: UITableViewDataSource {
    internal func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath){
        let level = frc.object(at: indexPath)
        let percentFull = Float(Int(level.capacity!) - Int(level.currentCount!)) / Float(level.capacity!)
        
        if level.name == "All Levels"{
            let cell = cell as! TotalCountTableViewCell
            cell.nameLabel.text = level.name
            cell.countLabel.text = FormatterUtility.shared.percentFormatter.string(from: NSNumber(value: percentFull))
            cell.progressBar.progress = percentFull
            cell.updateProgressBarColor()
        }else{
            let cell = cell as! LevelCountTableViewCell
            cell.nameLabel.text = level.name
            cell.countLabel.text = "\(level.currentCount!)"
            cell.progressBar.progress = percentFull
            cell.updateProgressBarColor()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionResults = frc.sections![section]
        let level = sectionResults.objects!.first as! Level
        
        return level.structure!.name
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard
            let results = frc.sections?[section],
            let level = results.objects?.first as? Level,
            let updatedDate = level.updatedAt else {
                return "Error determining updated date"
        }
        return "Updated " + dateFormatter.string(from: updatedDate)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return frc.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = frc.sections else {
            return 0
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let level = frc.object(at: indexPath) 
        var reuseID: String
        if level.name == "All Levels"{
            reuseID = "summaryCell"
        }else{
            reuseID = "levelCell"
        }
        
        let cell = parkingTableView.dequeueReusableCell(withIdentifier: reuseID, for: indexPath)
        configureCell(cell, atIndexPath: indexPath)

        return cell
    }
}

extension ParkingViewController: GenericFRCDelegate {
    func controllerDidChangeContent() {
        guard let structures = frc.sections else { return }
        for (index, str) in structures.enumerated() {
            guard let lastUpdatedDate = (str.objects as? [Level])?.sorted(by: { $0.updatedAt!.compare($1.updatedAt!) == .orderedAscending }).last?.updatedAt else { return }
            parkingTableView.beginUpdates()
            parkingTableView.footerView(forSection: index)?.textLabel?.text = "Updated \(dateFormatter.string(from: lastUpdatedDate))"
            parkingTableView.endUpdates()
        }
    }
}
