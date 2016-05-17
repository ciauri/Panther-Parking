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
        var colors = Constants.Colors.chartColors
        
        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        formatter.timeStyle = .MediumStyle
        
        
        
        var dataSets: [LineChartDataSet] = []
        var dates = Set<NSDate>()
//        var indices: [Int] = []
        var indices = Set<Double>()
//        var indices = Set<Int>()
        for level in structure.levels!{
            let l = level as! Level
            request.predicate = NSPredicate(format: "(level == %@) AND (updatedAt >= %@)", l, yesterday)
            context.performBlockAndWait({
                do{
                    let results = try context.executeFetchRequest(request) as! [Count]
                    
                    var yVals: [ChartDataEntry] = []
                    for (index, count) in results.enumerate(){
//                        indices.insert(index)
//                        count.updatedAt.t
                        dates.insert(count.updatedAt!)
                        indices.insert(count.updatedAt!.timeIntervalSinceReferenceDate)
//                        indices.append(index)
                        yVals.append(ChartDataEntry(value: count.availableSpaces! as Double, xIndex: index))
                    }
                    let set = LineChartDataSet(yVals: yVals, label: l.name)
                    set.circleRadius = 0
                    set.colors = [colors.removeFirst()]
                    dataSets.append(set)
                    
                }catch{
                    NSLog("fetch fail ruhroh")
                }
            })
            
            NSLog("\(indices.count)")
            NSLog("\(dataSets.first?.yVals.count)")
            let dateArray = Array(dates)
            let timestamps = dateArray.sort({$0.compare($1) == NSComparisonResult.OrderedAscending})
            let stringStamps = timestamps.map({return formatter.stringFromDate($0)})
            
            lineChart.data = LineChartData(xVals: stringStamps, dataSets: dataSets)
   
        }
        
    }
    
    func firstDayOfWeekWithDate(date: NSDate)->NSDate{
        var beginningOfWeek: NSDate?
        let calendar = NSCalendar.currentCalendar()
        calendar.rangeOfUnit(.WeekOfYear, startDate: &beginningOfWeek, interval: nil, forDate: date)
        
        return beginningOfWeek!
    }
    
    func hourlyDatesInRange(startDate: NSDate, endDate:NSDate) -> [NSDate]{
        var secondsBetween = startDate.timeIntervalSinceDate(endDate)
        var dates: [NSDate] = []
        
        while(secondsBetween > 0){
            dates.append(startDate.dateByAddingTimeInterval(360))
            secondsBetween -= 360
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
