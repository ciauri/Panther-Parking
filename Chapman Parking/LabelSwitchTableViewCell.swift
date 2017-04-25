//
//  LabelSwitchTableViewCell.swift
//  PantherPark
//
//  Created by Stephen Ciauri on 8/31/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import UIKit

class LabelSwitchTableViewCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var detailSwitch: UISwitch!
    
    weak var delegate: SwitchCellDelegate?

    @IBAction func switchToggled(_ sender: UISwitch) {
        delegate?.switchCell(self, toggledSwitch: detailSwitch)
    }
}
