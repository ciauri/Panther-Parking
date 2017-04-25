//
//  TotalCountTableViewCell.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/5/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import UIKit

class TotalCountTableViewCell: UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var countLabel: UILabel!
    @IBOutlet var progressBar: UIProgressView!
    
    var progressColor: UIColor {
        return UIColor.temperatureColor(fromPercentCompletion: progressBar.progress)
    }
    
    func updateProgressBarColor() {
        progressBar.progressTintColor = progressColor
    }

}
