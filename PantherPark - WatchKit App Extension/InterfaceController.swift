//
//  InterfaceController.swift
//  PantherPark - WatchKit App Extension
//
//  Created by Stephen Ciauri on 10/2/16.
//  Copyright © 2016 Stephen Ciauri. All rights reserved.
//

import WatchKit
import Foundation
import CoreGraphics


class InterfaceController: WKInterfaceController {
    @IBOutlet var image: WKInterfaceImage!
    
    var documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let imageLength = 202
        let frames = 360
        let size = CGSize(width: imageLength, height: imageLength)
        let opaque = false
        
        UIGraphicsBeginImageContextWithOptions(size, opaque, 0.0)
        let context = UIGraphicsGetCurrentContext()
        
        let point = CGPoint(x: imageLength/2, y: imageLength/2)
        let intervals = 2*CGFloat.pi/CGFloat(frames)

        let lineWidth = CGFloat(imageLength/10)
        let radius = CGFloat(imageLength/2)-lineWidth
        

        
        
        for centerX in 0...frames {
            let percent = Double(Double(centerX)/Double(frames))
            let endAngle = CGFloat(centerX)*intervals
//            context?.setLineWidth(5)
            context?.setStrokeColor(UIColor.temperatureColor(fromPercentCompletion: Float(percent)).cgColor)
            
            let k = UIBezierPath(arcCenter: point, radius: radius, startAngle: 0, endAngle: endAngle, clockwise: true)
            k.lineCapStyle = .round
            k.lineWidth = lineWidth
            k.stroke()
            

            
//            context?.addArc(center: point, radius: CGFloat(radius), startAngle: 0, endAngle: endAngle , clockwise: false)
//
//            context?.strokePath()

            let image = UIGraphicsGetImageFromCurrentImageContext()
            let data = UIImagePNGRepresentation(image!)
            
            let file = documentsPath.appending("/wat\(centerX).png")
            let url = URL(fileURLWithPath: file, isDirectory: false)
            do {
                try data?.write(to: url, options: .atomic)
            } catch let e{
                NSLog("Could not write data: \(e))")
            }
        }
        UIGraphicsEndImageContext()
        
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didAppear() {
        super.didAppear()
        let file = documentsPath.appending("/wat")
        NSLog("\(file)")
        let animatedImage = UIImage.animatedImageNamed(file, duration: 3)
        self.image.setImage(animatedImage)
        self.image.startAnimatingWithImages(in: NSRange.init(location: 0, length: 360), duration: 4, repeatCount: 1)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.animate(withDuration: 0.5) {
                self.image.setAlpha(0.0)
            }
        }

//        self.image.startAnimating()
//        self.image.startAnimatingWithImages(in: range, duration: 50, repeatCount: 5)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
