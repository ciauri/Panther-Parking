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
    let NOTIFICATIONS_ENABLED_INDEX_PATH = IndexPath(row: 0, section: 0)
    let STRUCTURES_ONLY_INDEX_PATH = IndexPath(row: 1, section: 0)
    
    fileprivate var notificationsEnabled: Bool {
        return NotificationService.sharedInstance.notificationsEnabled
    }
    
    fileprivate var structuresOnly: Bool {
        return NotificationService.sharedInstance.structuresOnly
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(reflectSystemNotificationStatus), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationService.sharedInstance.fetchAndUpdateSubscriptions(withCompletion: {
            self.updateCellsAnimated()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func updateCellsAnimated() {
        if let indexPaths = tableView.indexPathsForVisibleRows?.filter({$0.section > 0}) {
            for indexPath in indexPaths {
                let level = self.level(forIndexPath: indexPath)
                if let cell = tableView.cellForRow(at: indexPath) as? LabelSwitchTableViewCell {
                    cell.detailSwitch.setOn(Bool(truncating: level.notificationsEnabled!), animated: true)
                }
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return notificationsEnabled ? structures.count + 1 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case SETTINGS_SECTION:
            return notificationsEnabled ? 2 : 1
        default:
            return notificationsEnabled ? structuresOnly ? 1 : structures[section-1].levels?.count ?? 0 : 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case SETTINGS_SECTION:
            return "General Settings"
        default:
            return structures[section-1].name ?? ""
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case SETTINGS_SECTION:
            return notificationsEnabled ? SETTINGS_FOOTER_TEXT : nil
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "labelSwitch", for: indexPath) as! LabelSwitchTableViewCell
        
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
    
    fileprivate func configureLevelCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        let level = self.level(forIndexPath: indexPath)
        
        if indexPath.row == 0 {
            (cell as! LabelSwitchTableViewCell).label.text = "Entire Structure"
        } else {
            (cell as! LabelSwitchTableViewCell).label.text = level.name!
        }
        
        if let switchState = level.notificationsEnabled{
            let on = Bool(truncating: switchState)
            (cell as! LabelSwitchTableViewCell).detailSwitch.setOn(on, animated: false)
        } else {
            (cell as! LabelSwitchTableViewCell).detailSwitch.setOn(false, animated: false)
        }
        
    }
    
    // MARK: - Utility Functions
    
    fileprivate func level(forIndexPath indexPath: IndexPath) -> Level {
        var levels = Array(structures[(indexPath as NSIndexPath).section-1].levels!)
        levels.sort { (l1, l2) -> Bool in
            return l1.name! < l2.name!
        }
        return levels[indexPath.row]
    }
    
    fileprivate func indexPathsForLevelCells(includeAllLevels include: Bool) -> [IndexPath] {
        var indexPaths: [IndexPath] = []
        
        for (section, structure) in structures.enumerated() {
            var levels = Array(structure.levels!)
            levels.sort { (l1, l2) -> Bool in
                return l1.name! < l2.name!
            }
            
            for (row, level) in levels.enumerated() {
                if !include {
                    if level.name != "All Levels" {
                        indexPaths.append(IndexPath(row: row, section: section+1))
                    }
                } else {
                    indexPaths.append(IndexPath(row: row, section: section+1))
                }
                
            }
        }
        return indexPaths
    }
    
    fileprivate func toggleNotificationCells(_ enabled: Bool) {
        tableView.beginUpdates()
        var indexPaths = indexPathsForLevelCells(includeAllLevels: true)
        if structuresOnly {
            indexPaths = indexPaths.filter({$0.row == 0})
        }
        indexPaths.append(STRUCTURES_ONLY_INDEX_PATH)
        let range = 1...3
        let indexSet = IndexSet(integersIn: range)
        
        if enabled {
            tableView.insertRows(at: indexPaths, with: .automatic)
            tableView.insertSections(indexSet, with: .automatic)
            tableView.footerView(forSection: SETTINGS_SECTION)?.textLabel?.text = SETTINGS_FOOTER_TEXT
        } else {
            tableView.deleteRows(at: indexPaths, with: .automatic)
            tableView.deleteSections(indexSet, with: .automatic)
            tableView.footerView(forSection: SETTINGS_SECTION)?.textLabel?.text = nil

        }
        tableView.endUpdates()
    }
    
    fileprivate func toggleLevelCells(_ enabled: Bool) {
        tableView.beginUpdates()
        if enabled {
            tableView.deleteRows(at: indexPathsForLevelCells(includeAllLevels: false), with: .right)
        } else {
            tableView.insertRows(at: indexPathsForLevelCells(includeAllLevels: false), with: .right)
        }
        tableView.endUpdates()
    }
    
    @objc
    fileprivate func reflectSystemNotificationStatus() {
        let enabledCell = tableView.cellForRow(at: NOTIFICATIONS_ENABLED_INDEX_PATH) as! LabelSwitchTableViewCell
        if !notificationsEnabled && enabledCell.detailSwitch.isOn {
            enabledCell.detailSwitch.setOn(false, animated: true)
            toggleNotificationCells(false)
        }
    }

}

// MARK: - SwitchCellDelegate
extension NotificationSettingsTableViewController: SwitchCellDelegate {
    func switchCell(_ cell: LabelSwitchTableViewCell, toggledSwitch uiSwitch: UISwitch) {
        if let indexPath = tableView.indexPath(for: cell) {
            switch indexPath {
            case NOTIFICATIONS_ENABLED_INDEX_PATH:
                if uiSwitch.isOn {
                    NotificationService.sharedInstance.enableNotifications(self,
                                                                           success: {
                                                                        self.toggleNotificationCells(uiSwitch.isOn)
                                                                        }, failure: { 
                                                                        uiSwitch.setOn(false, animated: true)
                    })
                } else {
                    NotificationService.sharedInstance.disableNotifications()
                    toggleNotificationCells(uiSwitch.isOn)
                }
            case STRUCTURES_ONLY_INDEX_PATH:
                NotificationService.sharedInstance.structuresOnly = uiSwitch.isOn
                if uiSwitch.isOn {
                    for structure in structures {
                        if let levels = structure.levels {
                            for level in levels where level.name != "All Levels" {
                                NotificationService.sharedInstance.disableNotifications(for: level)
                            }
                        }
                    }
                }
                toggleLevelCells(uiSwitch.isOn)
            default:
                let level = self.level(forIndexPath: indexPath)
                if uiSwitch.isOn {
                    NotificationService.sharedInstance.enableNotifications(for: level)
                } else {
                    NotificationService.sharedInstance.disableNotifications(for: level)
                }
            }
        }
    }
    
    

}

// MARK: - Protocol Declaration
protocol SwitchCellDelegate: class {
    func switchCell(_ cell: LabelSwitchTableViewCell, toggledSwitch uiSwitch: UISwitch)
}
