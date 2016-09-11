//
//  SettingsTableViewController.swift
//  PantherPark
//
//  Created by Stephen Ciauri on 8/31/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    @IBOutlet weak var notificationDetailLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notificationDetailLabel.text = NotificationService.sharedInstance.notificationsEnabled ? "Enabled" : "Disabled"
        if let selectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRow, animated: animated)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "notificationSettings":
                prepareForNotificationSettings(withSegue: segue)
            case "chartSettings":
                break
            default:
                break
            }
        }
    }
    
  
    
    
    fileprivate func prepareForNotificationSettings(withSegue segue: UIStoryboardSegue) {
        let notificationSettingsViewController = segue.destination as! NotificationSettingsTableViewController
        
        notificationSettingsViewController.structures = DataManager.sharedInstance.fetchAllStructures()
        
    }
        
 

}
