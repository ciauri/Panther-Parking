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
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func switchToggled(sender: UISwitch) {
        delegate?.switchCell(self, toggledSwitch: detailSwitch)
    }
}
