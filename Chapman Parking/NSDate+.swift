//
//  NSDate+.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/6/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation

public extension NSDate {
    public class func ISOStringFromDate(date: NSDate) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.timeZone = NSTimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        return dateFormatter.stringFromDate(date)
    }
    
    public class func dateFromISOString(string: String) -> NSDate {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.timeZone = NSTimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        return dateFormatter.dateFromString(string)!
    }
    
    func dateFromTime(hour: Int?, minute: Int?, second: Int?) -> NSDate? {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Hour,.Minute,.Second], fromDate: self)
        
        return calendar.dateBySettingHour(hour ?? components.hour, minute: minute ?? components.minute, second: second ?? components.second, ofDate: self, options: .MatchFirst)
    }
}