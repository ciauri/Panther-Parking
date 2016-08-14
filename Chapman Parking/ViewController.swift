//
//  ViewController.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 8/14/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import UIKit
import Charts

class ViewController: UIViewController {
    
    @IBOutlet var chart: LineChartView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let months = [0,1,2,3,4,5,6,7,8,9,10,11]
        var dataEntries: [ChartDataEntry] = []
        
        let entry1 = ChartDataEntry(value: 1, xIndex: 0)
        let entry2 = ChartDataEntry(value: 2, xIndex: 1)
        let entry3 = ChartDataEntry(value: 3, xIndex: 2)
        let entry4 = ChartDataEntry(value: 8, xIndex: 5)
        let entry5 = ChartDataEntry(value: 15, xIndex: 11)
        
        dataEntries = [entry1, entry2, entry3, entry4, entry5]
        let dataSet = LineChartDataSet(yVals: dataEntries, label: "wat")
        let chartData = LineChartData(xVals: months, dataSet: dataSet)
        
        chart.data = chartData


        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
