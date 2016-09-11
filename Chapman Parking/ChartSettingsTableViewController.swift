//
//  ChartSettingsTableViewController.swift
//  PantherPark
//
//  Created by Stephen Ciauri on 8/31/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import UIKit

class ChartSettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var allLinesSwitch: UISwitch! {
        didSet {
            let defaults = UserDefaults.standard
            allLinesSwitch.setOn(defaults.bool(forKey: Constants.DefaultsKeys.cumulativeLine), animated: false)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    @IBAction func allLevelsSwitchToggled(_ sender: UISwitch) {
        let defaults = UserDefaults.standard
        defaults.set(sender.isOn, forKey: Constants.DefaultsKeys.cumulativeLine)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

}
