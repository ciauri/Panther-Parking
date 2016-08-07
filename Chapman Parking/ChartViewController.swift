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
    
    var structure: Structure!

    override func viewDidLoad() {
        super.viewDidLoad()
        initChart(withResolution: 60)

        // Do any additional setup after loading the view.
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func initChart(withResolution minuteResolution: Int){
        let context = DataManager.sharedInstance.managedObjectContext
        let request = NSFetchRequest(entityName: "Count")
        let today = NSDate().dateFromTime(nil, minute: nil, second: 0)!
        let yesterday = NSDate().dateByAddingTimeInterval(-86400).dateFromTime(nil, minute: nil, second: 0)!
        let chronoSort = NSSortDescriptor(key: "updatedAt", ascending: true)
        request.sortDescriptors = [chronoSort]
        var colors = ChartColorTemplates.colorful() + ChartColorTemplates.vordiplom()
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .ShortStyle
        
     
        var dataSets: [LineChartDataSet] = []
        var timeIntervals = self.datesInRange(yesterday, endDate: today, withInterval: 60)
        timeIntervals.sortInPlace({$0.compare($1) == .OrderedAscending})
        for level in structure.levels!{
            let l = level as! Level
            request.predicate = NSPredicate(format: "(level == %@) AND (updatedAt >= %@)", l, yesterday)
            context.performBlockAndWait({
                do{
                    let results = try context.executeFetchRequest(request) as! [Count]
                    var plotDict: [NSDate:Int] = [:]
                    
                    // Normalize time to have 00 seconds for easier matching
                    results.forEach({$0.updatedAt = $0.updatedAt?.dateFromTime(nil, minute: nil, second: 0)})
                    
                    timeIntervals.forEach({plotDict[$0] = -1})
                    results.forEach({plotDict[$0.updatedAt!] = Int($0.availableSpaces!)})
                    
                    let flattenedPlot = plotDict.map({(date: $0.0, count: $0.1)})
                    var sortedPlot = flattenedPlot.sort({$0.0.date.compare($0.1.date) == .OrderedAscending})
                    
                    for (index, element) in sortedPlot.enumerate() where element.count == -1 {
                        if index != 0 {
                            sortedPlot[index] = (element.date, sortedPlot[index-1].count)
                        } else {
                            let count = self.fetchMostRecentCount(fromDate: element.date, onLevel: l, usingContext: context)
                            sortedPlot[index] = (element.date, Int(count?.availableSpaces! ?? 0))
                        }
                        
                    }
                    
                    var yVals: [ChartDataEntry] = []
                    
                    for (index, element) in sortedPlot.enumerate() {
                        if index % minuteResolution == 0 {
                            yVals.append(ChartDataEntry(value: Double(element.count), xIndex: index))
                        }
                    }

                    NSLog("\(yVals.count)")
                    let set = LineChartDataSet(yVals: yVals, label: l.name)
                    if minuteResolution >= 60 {
                        set.mode = .CubicBezier
                    }
                    set.lineWidth = 3
                    set.drawCirclesEnabled = false
                    set.colors = [colors.removeFirst()]
                    dataSets.append(set)
                    
                }catch{
                    NSLog("fetch fail ruhroh")
                }
            })
            
            
   
        }
        
        let stringStamps = timeIntervals.map({return formatter.stringFromDate($0)})
        lineChart.data = LineChartData(xVals: stringStamps, dataSets: dataSets)
        lineChart.animate(yAxisDuration: 2, easingOption: .EaseOutElastic)
        
    }
    
    
    private func countThatMatches(date: NSDate, withCounts counts: [Count]) -> Count? {
        let calendar = NSCalendar.currentCalendar()
        for count in counts {
            if calendar.compareDate(date, toDate: count.updatedAt!, toUnitGranularity: .Minute) == .OrderedSame {
                return count
            }
        }
        return nil
    }
    
    private func fetchMostRecentCount(fromDate date: NSDate, onLevel level: Level, usingContext context: NSManagedObjectContext) -> Count? {
        let request = NSFetchRequest(entityName: "Count")
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
        request.predicate = NSPredicate(format: "(level == %@) AND (updatedAt <= %@)", level, date)
        request.fetchLimit = 1
        do{
            return try (context.executeFetchRequest(request) as? [Count])?.first
        } catch {
            NSLog("error")
            return nil
        }
    }
    
    func firstDayOfWeekWithDate(date: NSDate)->NSDate{
        var beginningOfWeek: NSDate?
        let calendar = NSCalendar.currentCalendar()
        calendar.rangeOfUnit(.WeekOfYear, startDate: &beginningOfWeek, interval: nil, forDate: date)
        
        return beginningOfWeek!
    }
    
    func datesInRange(startDate: NSDate, endDate:NSDate, withInterval seconds: Double) -> [NSDate]{
        var secondsBetween = endDate.timeIntervalSinceDate(startDate)
        var dates: [NSDate] = []
        
        while(secondsBetween > 0){
            dates.append(startDate.dateByAddingTimeInterval(secondsBetween))
            secondsBetween -= seconds
        }
        
        return dates
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
