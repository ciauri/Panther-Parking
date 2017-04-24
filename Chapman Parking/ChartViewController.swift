//
//  ChartViewController.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/16/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import UIKit
import CoreData
import Charts

/*
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}
*/

class ChartViewController: UIViewController {

    @IBOutlet var lineChart: LineChartView!
    @IBOutlet var levelSelector: UISegmentedControl!
    @IBOutlet var scaleSelector: UISegmentedControl!
    @IBOutlet var spinner: UIActivityIndicatorView!
    @IBOutlet var progress: UIProgressView!
    @IBOutlet var yAxisLabel: UILabel!
    
    let daysWorthOfSeconds = 86400
    let shouldDrawCumulativeLine = UserDefaults.standard.bool(forKey: "showCumulativeLine")

    var structure: Structure!
    var levels: [Level]!
    var resolution: Int = 60
    var numberOfDays: Int = 1
    var selectedLevels: [Level]!
    
    lazy var today: Date = Date().dateFromTime(nil, minute: nil, second: 0)!
    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = structure.name
        
        if let levels = structure.levels {
            self.levels = Array(levels)
            self.levels.sort(by: {$0.0.name! < $0.1.name!})
            if !shouldDrawCumulativeLine {
                // Because "All Levels" will always be first alphabetically... Yeah, yeah its bad, I know
                self.levels.removeFirst()
            }
            selectedLevels = self.levels
            DispatchQueue.main.async(execute: {
                self.updateLevels()
                self.initChart(self.selectedLevels, withResolution: self.resolution, numberOfDays: self.numberOfDays)
            })
            
            addLevelsToLevelSelector()
            rotateAxisLabel()
            levelSelector.selectedSegmentIndex = 0
        }
    }
    

    
    fileprivate func rotateAxisLabel() {
        yAxisLabel.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi/2))
        yAxisLabel.layoutIfNeeded()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func timeFrameSelected(_ selector: UISegmentedControl) {
        lineChart.fitScreen()
        if selector.selectedSegmentIndex == 0 {
            formatter.dateStyle = .none
            numberOfDays = 1
        } else {
            formatter.dateStyle = .short
            numberOfDays = 7
        }
        DispatchQueue.main.async(execute: {
            self.updateLevels()
            self.initChart(self.selectedLevels, withResolution: self.resolution, numberOfDays: self.numberOfDays)
        })
    }
    
    @IBAction func levelSelected(_ selector: UISegmentedControl) {
        if selector.selectedSegmentIndex == 0 {
            selectedLevels = levels
        } else {
            let index = shouldDrawCumulativeLine ? selector.selectedSegmentIndex : selector.selectedSegmentIndex-1
            selectedLevels = [levels[index]]
        }
        DispatchQueue.main.async(execute: {
            self.updateLevels()
            self.initChart(self.selectedLevels, withResolution: self.resolution, numberOfDays: self.numberOfDays)
        })
    }
    
    fileprivate func updateLevels(){
        let pastDate = today.addingTimeInterval(-Double(daysWorthOfSeconds*(numberOfDays-1))).dateFromTime(0, minute: 0, second: 0)!
        var completedCalls = 0
        spinner.startAnimating()
        progress.progress = 0
        selectedLevels.forEach({
            DataManager.sharedInstance.update($0,
                startDate: pastDate,
                endDate: today,
                completion: {_ in
                    completedCalls += 1
                    DispatchQueue.main.async(execute: {
                        self.progress.setProgress(Float(completedCalls)/Float(self.selectedLevels.count), animated: true)
                    })
                    if completedCalls == self.selectedLevels.count {
                        DispatchQueue.main.async(execute: {
                            self.spinner.stopAnimating()
                            self.initChart(self.selectedLevels, withResolution: self.resolution, numberOfDays: self.numberOfDays)
                        })
                        
                    }
                    
            })
        })
    }
    
    fileprivate func addLevelsToLevelSelector() {
        levelSelector.removeAllSegments()
        var levelNames = levels.map({$0.name!})
        levelNames.sort()
        
        levelSelector.insertSegment(withTitle: "All", at: 0, animated: false)
        for (index, name) in levelNames.enumerated() {
            if name == "All Levels" {
                levelSelector.removeSegment(at: 0, animated: false)
                levelSelector.insertSegment(withTitle: "All", at: index, animated: false)
            } else {
                levelSelector.insertSegment(withTitle: name, at: index+1, animated: false)
            }
        }
    }
    
    fileprivate func dataSet(named levelName: String, withCounts counts: [Count], onTimeline timeline: [Date], withResolutionInMinutes resolution: Int) -> LineChartDataSet {
        
        var yVals: [ChartDataEntry] = []
        
        for element in counts {
            let count = Double(element.availableSpaces!)
            let index = element.updatedAt!.timeIntervalSince(timeline.first!)/60
            yVals.append(ChartDataEntry(x: index, y: count))
        }

        
        // Draws the line to the beginning and end of the visible chart
        if let first = yVals.first,
            let last = yVals.last {
            
            if last.x < Double(timeline.count-1) {
                let count = last.y
                let index = Double(timeline.count-1)
                yVals.append(ChartDataEntry(x: index, y: count))
            }
            if first.x > Double(0) {
                let count = first.y
                let index = 0.0
                yVals.insert(ChartDataEntry(x: index, y: count), at: 0)
            }
        }

        let set = LineChartDataSet(values: yVals, label: levelName)
        set.lineWidth = 3
        set.drawCirclesEnabled = false
        
        return set
    }
    
    
    func initChart(_ levels: [Level], withResolution minuteResolution: Int, numberOfDays days: Int){
        var colors =  ChartColorTemplates.colorful() + ChartColorTemplates.vordiplom()
        let days = days-1
        let pastDate = today.addingTimeInterval(-Double(daysWorthOfSeconds*days)).dateFromTime(0, minute: 0, second: 0)!

        var dataSets: [LineChartDataSet] = []
        let timeIntervals = Date.datesInRange(pastDate, endDate: today, withInterval: 60)

        for level in levels{
            let results = DataManager.sharedInstance.countsOn(level, since: pastDate)
            let set = dataSet(named: level.name!, withCounts: results, onTimeline: timeIntervals, withResolutionInMinutes: 60)
            
            if selectedLevels.count == 1 {
                var offset = 0
                if !shouldDrawCumulativeLine {
                    offset = 1
                }
                set.colors = [colors[levelSelector.selectedSegmentIndex-offset]]
            } else {
                set.colors = [colors.removeFirst()]
            }
            set.mode = .linear
            set.fill = Fill(color: set.colors.first!)
            set.valueFormatter = DefaultValueFormatter(decimals: 3)
            set.drawFilledEnabled = true
            set.drawValuesEnabled = false
            dataSets.append(set)
        }
        
        dataSets.sort(by: {(set1, set2) in
            set1.label! < set2.label!
        })
        
        let stringStamps = timeIntervals.map({return formatter.string(from: $0).replacingOccurrences(of:",", with: "\n")})
        lineChart.xAxis.valueFormatter = IndexAxisValueFormatter(values: stringStamps)
        lineChart.rightAxis.enabled = false
        lineChart.leftAxis.granularity = 1
        lineChart.leftAxis.axisMinimum = 0
        lineChart.leftAxis.labelPosition = .insideChart
        lineChart.legend.horizontalAlignment = .center
        lineChart.legend.verticalAlignment = .top
        lineChart.legend.orientation = .horizontal
        lineChart.xAxis.avoidFirstLastClippingEnabled = true
        lineChart.chartDescription?.text = ""
        lineChart.data = LineChartData(dataSets: dataSets)
    }

}


