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
        initChart()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func initChart(){
        let context = DataManager.sharedInstance.managedObjectContext
        let request = NSFetchRequest(entityName: "Count")
        let today = NSDate()
        let yesterday = NSDate().dateByAddingTimeInterval(-86400)
//        let dateArray = hourlyDatesInRange(yesterday, endDate: today)
        let chronoSort = NSSortDescriptor(key: "updatedAt", ascending: true)
        request.sortDescriptors = [chronoSort]
        var colors = ChartColorTemplates.colorful() + ChartColorTemplates.vordiplom()
//        var colors = Constants.Colors.chartColors
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .MediumStyle
        
//        let calendar = NSCalendar.currentCalendar()
        
        
        
        var dataSets: [LineChartDataSet] = []
//        var dates = Set<NSDate>()
//        var indices: [Int] = []
//        var indices = Set<Double>()
//        var indices = Set<Int>()
        for level in structure.levels!{
            let l = level as! Level
            request.predicate = NSPredicate(format: "(level == %@) AND (updatedAt >= %@)", l, yesterday)
            context.performBlockAndWait({
                do{
                    let results = try context.executeFetchRequest(request) as! [Count]
                    
                    let oneMinuteIntervals = self.datesInRange(yesterday, endDate: today, withInterval: 60)
                    var yVals: [ChartDataEntry] = []

                    
                    var lastCount: Int?
                    for (index, date) in oneMinuteIntervals.enumerate() {
                        var countToAdd: Int
                        if let match = self.countThatMatches(date, withCounts: results) {
                            countToAdd = Int(match.availableSpaces!)
                        } else {
                            if let count = lastCount {
                                countToAdd = count
                            } else if let count = self.fetchMostRecentCount(fromDate: date, onLevel: l, usingContext: context){
                                countToAdd = Int(count.availableSpaces!)
                            } else {
                                countToAdd = 0
                            }
                            
                        }
                        lastCount = countToAdd
                        yVals.append(ChartDataEntry(value: Double(countToAdd), xIndex: index))
                        
                    }

                    NSLog("\(yVals.count)")
                    let set = LineChartDataSet(yVals: yVals, label: l.name)
                    set.lineWidth = 3
                    set.drawCirclesEnabled = false
                    set.colors = [colors.removeFirst()]
                    dataSets.append(set)
                    
                }catch{
                    NSLog("fetch fail ruhroh")
                }
            })
            
//            NSLog("\(indices.count)")
//            NSLog("\(dataSets.first?.yVals.count)")
//            let dateArray = Array(dates)
//            let timestamps = dateArray.sort({$0.compare($1) == NSComparisonResult.OrderedAscending})
//            let stringStamps = timestamps.map({return formatter.stringFromDate($0)})
            let xvals = Array(0...1439)
            
            lineChart.data = LineChartData(xVals: xvals, dataSets: dataSets)
   
        }
        
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
