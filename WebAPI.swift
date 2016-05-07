//
//  WebAPI.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/4/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation

class WebAPI{
    
    private class func downloadParkingData(updateType: UpdateType, withBlock: (JSONReport) -> Void){
        var url = Constants.URLs.stephenParkingURL
        
        if updateType == UpdateType.Latest{
            url = url.URLByAppendingPathComponent("latest")
        }
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url) {(data, response, error) in
            if let d = data{
                let report = parseParkingData(d)
                withBlock(report)
            }
        }
        task.resume()
    }
    
    private class func parseParkingData(data: NSData) -> JSONReport{
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as! [String: AnyObject]
        
        return JSONReport(json: json)!
    }
    
    class func generateReport(updateType: UpdateType, withBlock block: ((JSONReport) -> Void)){
        downloadParkingData(updateType, withBlock: {report in
            block(report)
        })
        
    }
}


enum UpdateType{
    case All
    case Latest
}