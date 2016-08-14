//
//  WebAPI.swift
//  Chapman Parking
//
//  Created by Stephen Ciauri on 5/4/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import Foundation
import CloudKit

/**
 Defunct custom web API. Re-implement as-needed.

class WebAPI: ParkingAPI{
    
    static let sharedInstance = WebAPI() as ParkingAPI
    
    var container: CKContainer
    var publicDB: CKDatabase
    
    init(){
        container = CKContainer.defaultContainer()
        publicDB = container.publicCloudDatabase
    }

    
    private func downloadParkingData(updateType: UpdateType, sinceDate date: NSDate? = nil, withBlock: (JSONReport) -> Void){
        
        var url = Constants.URLs.stephenParkingURL
        
        if updateType == UpdateType.Latest{
            url = url.URLByAppendingPathComponent("latest")
        }else if updateType == .SinceLast, let date = date{
            url = url.URLByAppendingPathComponent("since/\(NSDate.ISOStringFromDate(date))")
            NSLog("\(url)")
        }
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url) {(data, response, error) in
            if let d = data{
                let report = self.parseParkingData(d)
                withBlock(report)
            }
        }
        task.resume()
    }
    
    private func parseParkingData(data: NSData) -> JSONReport{
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as! [String: AnyObject]
        
        return JSONReport(json: json)!
    }
    
    func generateReport(updateType: UpdateType, sinceDate date: NSDate? = nil, withBlock block: ((CPReport) -> Void)){
        downloadParkingData(updateType, sinceDate: date,  withBlock: {report in
            block(report)
        })
        
    }
    
    
    
}

// TODO: Implement "SinceLast"

 */

