//
//  ChartViewController.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/16/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import UIKit
import Charts
import CoreData

class ChartViewController: UIViewController {

    @IBOutlet var lineChart: LineChartView!
    @IBOutlet var levelSelector: UISegmentedControl!
    @IBOutlet var scaleSelector: UISegmentedControl!
    @IBOutlet var spinner: UIActivityIndicatorView!
    @IBOutlet var progress: UIProgressView!
    @IBOutlet var yAxisLabel: UILabel!
    
    var structure: Structure!
    var levels: [Level]!
    
    
    let daysWorthOfSeconds = 86400
    lazy var today: NSDate = NSDate().dateFromTime(nil, minute: nil, second: 0)!
    lazy var formatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .NoStyle
        formatter.timeStyle = .ShortStyle
        return formatter
    }()
    
    var resolution: Int = 60
    var numberOfDays: Int = 1
    var selectedLevels: [Level]!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = structure.name
        addLevelsToLevelSelector()
        rotateAxisLabel()
        levelSelector.selectedSegmentIndex = 0

        if let levels = structure.levels {
            self.levels = Array(levels)
            self.levels.sortInPlace({$0.0.name < $0.1.name})
            selectedLevels = self.levels
            dispatch_async(dispatch_get_main_queue(), {
                self.updateLevels()
                self.initChart(self.selectedLevels, withResolution: self.resolution, numberOfDays: self.numberOfDays)
            })
        }
    }
    
    private func rotateAxisLabel() {
        yAxisLabel.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI/2))
        yAxisLabel.layoutIfNeeded()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func timeFrameSelected(selector: UISegmentedControl) {
        lineChart.fitScreen()
        if selector.selectedSegmentIndex == 0 {
            formatter.dateStyle = .NoStyle
            numberOfDays = 1
        } else {
            formatter.dateStyle = .ShortStyle
            numberOfDays = 7
        }
        dispatch_async(dispatch_get_main_queue(), {
            self.updateLevels()
            self.initChart(self.selectedLevels, withResolution: self.resolution, numberOfDays: self.numberOfDays)
        })
    }
    
    @IBAction func levelSelected(selector: UISegmentedControl) {
        if selector.selectedSegmentIndex == 0 {
            selectedLevels = levels
        } else {
            selectedLevels = [levels[selector.selectedSegmentIndex]]
        }
        dispatch_async(dispatch_get_main_queue(), {
            self.updateLevels()
            self.initChart(self.selectedLevels, withResolution: self.resolution, numberOfDays: self.numberOfDays)
        })
    }
    
    private func updateLevels(){
        let pastDate = today.dateByAddingTimeInterval(-Double(daysWorthOfSeconds*(numberOfDays-1))).dateFromTime(0, minute: 0, second: 0)!
        var completedCalls = 0
        spinner.startAnimating()
        progress.progress = 0
        selectedLevels.forEach({
            DataManager.sharedInstance.update($0,
                startDate: pastDate,
                endDate: today,
                completion: {_ in
                    completedCalls += 1
                    dispatch_async(dispatch_get_main_queue(), {
                        self.progress.setProgress(Float(completedCalls)/Float(self.selectedLevels.count), animated: true)
                    })
                    if completedCalls == self.selectedLevels.count {
                        dispatch_async(dispatch_get_main_queue(), {
                            self.spinner.stopAnimating()
                            self.initChart(self.selectedLevels, withResolution: self.resolution, numberOfDays: self.numberOfDays)
                        })
                        
                    }
                    
            })
        })
    }
    
    private func addLevelsToLevelSelector() {
        levelSelector.removeAllSegments()
        guard let levels = structure.levels else {return}
        var levelNames = levels.map({$0.name!})
        levelNames.sortInPlace()
        
        for (index, name) in levelNames.enumerate() {
            if index == 0 {
                levelSelector.insertSegmentWithTitle("All", atIndex: index, animated: true)
            } else {
                levelSelector.insertSegmentWithTitle(name, atIndex: index, animated: true)
            }
        }
    }
    
    private func dataSet(named levelName: String, withCounts counts: [Count], onTimeline timeline: [NSDate], withResolutionInMinutes resolution: Int) -> LineChartDataSet {
        
        var yVals: [ChartDataEntry] = []
        
        for element in counts {
            let count = Double(element.availableSpaces!)
            let index = element.updatedAt!.timeIntervalSinceDate(timeline.first!)/60
            yVals.append(ChartDataEntry(x: index, y: count))
        }

        
        // Draws the line to the beginning and end of the visible chart
        if let first = yVals.first,
            last = yVals.last {
            
            if Int(last.x) < timeline.count-1 {
                let count = last.y
                let index = Double(timeline.count-1)
                yVals.append(ChartDataEntry(x: index, y: count))
            }
            if first.x > 0 {
                let count = first.y
                let index = 0.0
                yVals.insert(ChartDataEntry(x: index, y: count), atIndex: 0)
            }
        }

        let set = LineChartDataSet(values: yVals, label: levelName)
        set.lineWidth = 3
        set.drawCirclesEnabled = false
        
        return set
    }
    
    
    func initChart(levels: [Level], withResolution minuteResolution: Int, numberOfDays days: Int){
        var colors =  ChartColorTemplates.colorful() + ChartColorTemplates.vordiplom()
        let days = days-1
        let pastDate = today.dateByAddingTimeInterval(-Double(daysWorthOfSeconds*days)).dateFromTime(0, minute: 0, second: 0)!

        var dataSets: [LineChartDataSet] = []
        let timeIntervals = NSDate.datesInRange(pastDate, endDate: today, withInterval: 60)

        for level in levels{
            let results = DataManager.sharedInstance.countsOn(level, since: pastDate)
            let set = dataSet(named: level.name!, withCounts: results, onTimeline: timeIntervals, withResolutionInMinutes: 60)
            
            if selectedLevels.count == 1 {
                set.colors = [colors[levelSelector.selectedSegmentIndex]]
            } else {
                set.colors = [colors.removeFirst()]
            }
            set.mode = .Linear
            set.fill = Fill(color: set.colors.first!)
            set.drawFilledEnabled = true
            set.drawValuesEnabled = false
            dataSets.append(set)
        }
        
        dataSets.sortInPlace({(set1, set2) in
            set1.label < set2.label
        })
        
        let stringStamps = timeIntervals.map({return formatter.stringFromDate($0).stringByReplacingOccurrencesOfString(",", withString: "\n")})
        let valueFormatter = DateValueFormatter(withStringArray: stringStamps)
        
        lineChart.xAxis.valueFormatter = valueFormatter
        lineChart.xAxis.labelRotationAngle = -45
        lineChart.xAxis.labelCount = 7
        
        lineChart.rightAxis.enabled = false
        lineChart.leftAxis.granularity = 1
        lineChart.leftAxis.axisMinimum = 0
        lineChart.leftAxis.labelPosition = .InsideChart
        lineChart.legend.horizontalAlignment = .Center
        lineChart.legend.verticalAlignment = .Top
        lineChart.legend.orientation = .Horizontal
        lineChart.descriptionText = ""
        lineChart.data = LineChartData(dataSets: dataSets)
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

class DateValueFormatter: NSObject, IAxisValueFormatter {
    private var stringArray: [String]
    
    override private init() {
        stringArray = []
        super.init()
    }
    
    init(withStringArray array: [String]) {
        self.stringArray = array
        super.init()
    }
    
    func stringForValue(value: Double, axis: AxisBase?) -> String {
        if value == 0 {
            return ""
        } else {
            if value > Double(stringArray.count-1) {
                return ""
            } else {
                return stringArray[Int(value)]
            }
        }
    }
}
