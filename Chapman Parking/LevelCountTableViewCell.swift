//
//  LevelCountTableViewCell.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/5/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//
import UIKit

class LevelCountTableViewCell: UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var countLabel: UILabel!
    @IBOutlet var progressBar: UIProgressView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}
