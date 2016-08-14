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
    
    var structure: Structure!
    var levels: [Level]!
    
    
    let daysWorthOfSeconds = 86400
    lazy var today: NSDate = NSDate()
    lazy var formatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .ShortStyle
        return formatter
    }()
    
    var resolution: Int = 60
    var numberOfDays: Int = 1
    var selectedLevels: [Level]!
    
//    let today = NSDate()
//    let yesterday = NSDate().dateByAddingTimeInterval(-Double(daysWorthOfSeconds*days)).dateFromTime(0, minute: 0, second: 0)!
    


    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = structure.name
        addLevelsToLevelSelector()
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
        

        // Do any additional setup after loading the view.
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func timeFrameSelected(selector: UISegmentedControl) {
        if selector.selectedSegmentIndex == 0 {
            numberOfDays = 1
        } else {
            numberOfDays = 7
        }
        dispatch_async(dispatch_get_main_queue(), {
            self.updateLevels()
            self.initChart(self.selectedLevels, withResolution: self.resolution, numberOfDays: self.numberOfDays)
        })
    }
    
    @IBAction func levelSelected(selector: UISegmentedControl) {
        NSLog("\(selector.selectedSegmentIndex)")
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
                        self.progress.progress = Float(completedCalls/self.selectedLevels.count)
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
    
    
    
    
    /// Maps the results array onto a continuous array of tuples containing `date` and `count`
    /// - Note:
    ///     Results array dates are modified to have the `second` DateComponent set to 0. This allows for a better
    ///       and more efficient hit rate of date comparisons. Timeline should have the same quality. Use `dateFromTime`
    ///       on input timeline.
    /// - Parameters:
    ///     - results: List of count objects
    ///     - fromLevel: The `Level` object the results belong to
    ///     - intoTimeline: Continuous array of NSDates that the results should be mapped onto
    /// - Complexity:
    ///     O(nlogn)...
    private func integrateAndSort(results: [Count], fromLevel level: Level, intoTimeline timeline: [NSDate]) -> [(date: NSDate, count: Int)] {
        var plotDict: [NSDate:Int] = [:]
        
        // Normalize time to have 00 seconds for easier matching
        results.forEach({$0.updatedAt = $0.updatedAt?.dateFromTime(nil, minute: nil, second: 0)})
        
        // Map plotDict to the desired timeline with default value used for filling in the blanks
        timeline.forEach({plotDict[$0] = -1})
        // Map results onto timeline
        results.forEach({plotDict[$0.updatedAt!] = Int($0.availableSpaces!)})
        
        // Make sortable
        let flattenedPlot = plotDict.map({(date: $0.0, count: $0.1)})
        
        // Sort
        var sortedPlot = flattenedPlot.sort({$0.0.date.compare($0.1.date) == .OrderedAscending})
        
        // Fill holes with data from previous point. If no previous point exists, fetch older data
        for (index, element) in sortedPlot.enumerate() where element.count == -1 {
            if index != 0 {
                sortedPlot[index] = (element.date, sortedPlot[index-1].count)
            } else {
                // Will execute a maximum of once per dataSet
                let context = try! DataManager.sharedInstance.createPrivateQueueContext()
                let count = DataManager.sharedInstance.mostRecentCount(fromDate: element.date, onLevel: level, usingContext: context)
                sortedPlot[index] = (element.date, Int(count?.availableSpaces! ?? 0))
            }
        }
        return sortedPlot
    }
    
    private func dataSetFor(level: Level, withdata data: [(date: NSDate, count: Int)], andResolutionInMinutes resolution: Int) -> LineChartDataSet {
        var yVals: [ChartDataEntry] = []
        
        for (index, element) in data.enumerate() {
            if index % resolution == 0 {
                yVals.append(ChartDataEntry(value: Double(element.count), xIndex: index))
            }
        }
        
        let set = LineChartDataSet(yVals: yVals, label: level.name)

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
            let sortedPlot = integrateAndSort(results, fromLevel: level, intoTimeline: timeIntervals)
            let set = dataSetFor(level, withdata: sortedPlot, andResolutionInMinutes: minuteResolution)
            
            if selectedLevels.count == 1 {
                set.colors = [colors[levelSelector.selectedSegmentIndex]]
            } else {
                set.colors = [colors.removeFirst()]
            }
            set.mode = .Linear
            set.fill = ChartFill(color: set.colors.first!)
//            set.fill = ChartFill(color: set.colors.first!)
            set.drawFilledEnabled = true
            set.valueFormatter?.zeroSymbol = ""
            set.valueFormatter?.maximumSignificantDigits = 3
            dataSets.append(set)
        }
        
        dataSets.sortInPlace({(set1, set2) in
            set1.label < set2.label
        })
        
        let stringStamps = timeIntervals.map({return formatter.stringFromDate($0).stringByReplacingOccurrencesOfString(",", withString: "\n")})
        lineChart.rightAxis.enabled = false
        lineChart.leftAxis.granularity = 1
        lineChart.leftAxis.axisMinValue = 0
        lineChart.legend.horizontalAlignment = .Center
        lineChart.legend.verticalAlignment = .Top
        lineChart.legend.orientation = .Horizontal
        lineChart.xAxis.avoidFirstLastClippingEnabled = true
//        lineChart.animate(yAxisDuration: 2, easingOption: .EaseOutElastic)
        lineChart.descriptionText = ""
        lineChart.data = LineChartData(xVals: stringStamps, dataSets: dataSets)
    }
    
    
    /*
    private func countThatMatches(date: NSDate, withCounts counts: [Count]) -> Count? {
        let calendar = NSCalendar.currentCalendar()
        for count in counts {
            if calendar.compareDate(date, toDate: count.updatedAt!, toUnitGranularity: .Minute) == .OrderedSame {
                return count
            }
        }
        return nil
    }
    */
    

    


    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
