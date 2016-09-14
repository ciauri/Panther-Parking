//
//  NotificationSettingsTableViewController.swift
//  PantherPark
//
//  Created by Stephen Ciauri on 8/31/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import UIKit

class NotificationSettingsTableViewController: UITableViewController {
    
    var structures: [Structure]!
    
    let SETTINGS_SECTION: Int = 0
    let SETTINGS_FOOTER_TEXT = "Structure notifications notify you only when all levels in the structure are full."
    let NOTIFICATIONS_ENABLED_INDEX_PATH = NSIndexPath(forRow: 0, inSection: 0)
    let STRUCTURES_ONLY_INDEX_PATH = NSIndexPath(forRow: 1, inSection: 0)
    
    private var notificationsEnabled: Bool {
        return NotificationService.sharedInstance.notificationsEnabled
    }
    
    private var structuresOnly: Bool {
        return NotificationService.sharedInstance.structuresOnly
    }
    
    
    
   

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reflectSystemNotificationStatus), name: UIApplicationDidBecomeActiveNotification, object: nil)
        NotificationService.sharedInstance.fetchAndUpdateSubscriptions(withCompletion: {
            self.updateCellsAnimated()
        })
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func updateCellsAnimated() {
        if let indexPaths = tableView.indexPathsForVisibleRows?.filter({$0.section > 0}) {
            for indexPath in indexPaths {
                let level = self.level(forIndexPath: indexPath)
                if let cell = tableView.cellForRowAtIndexPath(indexPath) as? LabelSwitchTableViewCell {
                    cell.detailSwitch.setOn(Bool(level.notificationsEnabled!), animated: true)
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return notificationsEnabled ? structures.count + 1 : 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case SETTINGS_SECTION:
            return notificationsEnabled ? 2 : 1
        default:
            return notificationsEnabled ? structuresOnly ? 1 : structures[section-1].levels?.count ?? 0 : 1
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case SETTINGS_SECTION:
            return "General Settings"
        default:
            return structures[section-1].name ?? ""
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case SETTINGS_SECTION:
            return notificationsEnabled ? SETTINGS_FOOTER_TEXT : nil
        default:
            return nil
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("labelSwitch", forIndexPath: indexPath) as! LabelSwitchTableViewCell
        
        switch indexPath {
        case NOTIFICATIONS_ENABLED_INDEX_PATH:
            cell.label.text = "Notifications Enabled"
            cell.detailSwitch.setOn(notificationsEnabled, animated: false)
        case STRUCTURES_ONLY_INDEX_PATH:
            cell.label.text = "Structure Notifications Only"
            cell.detailSwitch.setOn(structuresOnly, animated: false)
        default:
            configureLevelCell(cell, atIndexPath: indexPath)
        }
        
        cell.delegate = self

        return cell
    }
    
    private func configureLevelCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let level = self.level(forIndexPath: indexPath)
        
        if indexPath.row == 0 {
            (cell as! LabelSwitchTableViewCell).label.text = "Entire Structure"
        } else {
            (cell as! LabelSwitchTableViewCell).label.text = level.name!
        }
        
        if let switchState = level.notificationsEnabled{
            let on = Bool(switchState)
            (cell as! LabelSwitchTableViewCell).detailSwitch.setOn(on, animated: false)
        } else {
            (cell as! LabelSwitchTableViewCell).detailSwitch.setOn(false, animated: false)
        }
        
    }
    
    // MARK: - Utility Functions
    
    private func level(forIndexPath indexPath: NSIndexPath) -> Level {
        var levels = Array(structures[indexPath.section-1].levels!)
        levels.sortInPlace { (l1, l2) -> Bool in
            return l1.name! < l2.name!
        }
        return levels[indexPath.row]
    }
    
    private func indexPathsForLevelCells(includeAllLevels include: Bool) -> [NSIndexPath] {
        var indexPaths: [NSIndexPath] = []
        
        for (section, structure) in structures.enumerate() {
            var levels = Array(structure.levels!)
            levels.sortInPlace { (l1, l2) -> Bool in
                return l1.name! < l2.name!
            }
            
            for (row, level) in levels.enumerate() {
                if !include {
                    if level.name != "All Levels" {
                        indexPaths.append(NSIndexPath(forRow: row, inSection: section+1))
                    }
                } else {
                    indexPaths.append(NSIndexPath(forRow: row, inSection: section+1))
                }
                
            }
        }
        return indexPaths
    }
    
    private func toggleNotificationCells(enabled: Bool) {
        tableView.beginUpdates()
        var indexPaths = indexPathsForLevelCells(includeAllLevels: true)
        if structuresOnly {
            indexPaths = indexPaths.filter({$0.row == 0})
        }
        indexPaths.append(STRUCTURES_ONLY_INDEX_PATH)
        let range = NSRange(1...3)
        let indexSet = NSIndexSet(indexesInRange: range)
        
        if enabled {
            tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
            tableView.insertSections(indexSet, withRowAnimation: .Automatic)
            tableView.footerViewForSection(SETTINGS_SECTION)?.textLabel?.text = SETTINGS_FOOTER_TEXT
        } else {
            tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
            tableView.deleteSections(indexSet, withRowAnimation: .Automatic)
            tableView.footerViewForSection(SETTINGS_SECTION)?.textLabel?.text = nil

        }
        tableView.endUpdates()
    }
    
    private func toggleLevelCells(enabled: Bool) {
        tableView.beginUpdates()
        if enabled {
            tableView.deleteRowsAtIndexPaths(indexPathsForLevelCells(includeAllLevels: false), withRowAnimation: .Right)
        } else {
            tableView.insertRowsAtIndexPaths(indexPathsForLevelCells(includeAllLevels: false), withRowAnimation: .Right)
        }
        tableView.endUpdates()
    }
    
    @objc
    private func reflectSystemNotificationStatus() {
        let enabledCell = tableView.cellForRowAtIndexPath(NOTIFICATIONS_ENABLED_INDEX_PATH) as! LabelSwitchTableViewCell
        if !notificationsEnabled && enabledCell.detailSwitch.on {
            enabledCell.detailSwitch.setOn(false, animated: true)
            toggleNotificationCells(false)
        }
    }
    
    
    
    

}

// MARK: - SwitchCellDelegate
extension NotificationSettingsTableViewController: SwitchCellDelegate {
    func switchCell(cell: LabelSwitchTableViewCell, toggledSwitch uiSwitch: UISwitch) {
        if let indexPath = tableView.indexPathForCell(cell) {
            switch indexPath {
            case NOTIFICATIONS_ENABLED_INDEX_PATH:
                if uiSwitch.on {
                    NotificationService.sharedInstance.enableNotifications(self)
                    if notificationsEnabled {
                        toggleNotificationCells(uiSwitch.on)
                    } else {
                        uiSwitch.setOn(false, animated: true)
                    }
                } else {
                    NotificationService.sharedInstance.disableNotifications()
                    toggleNotificationCells(uiSwitch.on)
                }
            case STRUCTURES_ONLY_INDEX_PATH:
                NotificationService.sharedInstance.structuresOnly = uiSwitch.on
                if uiSwitch.on {
                    for structure in structures {
                        if let levels = structure.levels {
                            for level in levels where level.name != "All Levels" {
                                NotificationService.sharedInstance.disableNotificationFor(level)
                            }
                        }
                    }
                }
                toggleLevelCells(uiSwitch.on)
            default:
                let level = self.level(forIndexPath: indexPath)
                if uiSwitch.on {
                    NotificationService.sharedInstance.enableNotificationFor(level)
                } else {
                    NotificationService.sharedInstance.disableNotificationFor(level)
                }
            }
        }
    }
    
    

}

// MARK: - Protocol Declaration
protocol SwitchCellDelegate: class {
    func switchCell(cell: LabelSwitchTableViewCell, toggledSwitch uiSwitch: UISwitch)
}
