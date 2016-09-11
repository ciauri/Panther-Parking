//
//  NSDate+.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/6/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation

public extension Date {
    public static func ISOStringFromDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        return dateFormatter.string(from: date)
    }
    
    public static func dateFromISOString(_ string: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        return dateFormatter.date(from: string)!
    }
    
    /// Returns a choronological list of NSDates within the desired range with interval in seconds
    static func datesInRange(_ startDate: Date, endDate:Date, withInterval seconds: Double) -> [Date]{
        var secondsBetween = endDate.timeIntervalSince(startDate)
        var dates: [Date] = []
        
        while(secondsBetween > 0){
            dates.insert(startDate.addingTimeInterval(secondsBetween), at: 0)
            secondsBetween -= seconds
        }
        
        return dates
    }
    
    /// Returns the localized first day of the week of the desired date
    static func firstDayOfWeekWithDate(_ date: Date)->Date{
        var beginningOfWeek: NSDate? = date as NSDate?
        let calendar = Calendar.current
        (calendar as NSCalendar).range(of: .weekOfYear, start: &beginningOfWeek, interval: nil, for: date)
        
        return beginningOfWeek! as Date
    }
    
    func dateFromTime(_ hour: Int?, minute: Int?, second: Int?) -> Date? {
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components([.hour,.minute,.second], from: self)
        
        return (calendar as NSCalendar).date(bySettingHour: hour ?? components.hour!, minute: minute ?? components.minute!, second: second ?? components.second!, of: self, options: .matchFirst)
    }
}
