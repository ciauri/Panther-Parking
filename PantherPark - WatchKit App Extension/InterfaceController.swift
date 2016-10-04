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
        
        
        
        let point = CGPoint(x: imageLength/2, y: imageLength/2)
        let intervals = 2*CGFloat.pi/CGFloat(frames)
        let lineWidth = CGFloat(imageLength/20)
        let radius = CGFloat(imageLength/2)-lineWidth
        

        
        var previousImage: UIImage?
        
        for centerX in 0...frames {
            UIGraphicsBeginImageContextWithOptions(size, opaque, 0.0)
            let context = UIGraphicsGetCurrentContext()
            let percent = Double(Double(centerX)/Double(frames))
            let startAngle = CGFloat(centerX-1)*intervals
            let endAngle = CGFloat(centerX)*intervals
//            context?.setLineWidth(5)
            context?.setStrokeColor(UIColor.temperatureColor(fromPercentCompletion: Float(percent)).cgColor)
            
            let k = UIBezierPath(arcCenter: point, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            k.lineCapStyle = .round
            k.lineWidth = lineWidth
            k.stroke()
            

            
//            context?.addArc(center: point, radius: CGFloat(radius), startAngle: 0, endAngle: endAngle , clockwise: false)
//
//            context?.strokePath()

            // Snapshot generated image
            let image = UIGraphicsGetImageFromCurrentImageContext()
            
            // If a previous image exists, layer it on top of the previous image
            if let previousImage = previousImage {
                previousImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
                image?.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height), blendMode: .normal, alpha: 1.0)
            }
            
            // Snapshot merged image
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            
            previousImage = newImage
            
            // Turn into data
            let data = UIImagePNGRepresentation(newImage!)
            
            // Create file path
            // Animated images follow the naming convention `imageNameX.png` where X is the frame number
            let file = documentsPath.appending("/wat\(centerX).png")
            let url = URL(fileURLWithPath: file, isDirectory: false)
            do {
                try data?.write(to: url, options: .atomic)
            } catch let e{
                NSLog("Could not write data: \(e))")
            }
            UIGraphicsEndImageContext()
        }

    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didAppear() {
        super.didAppear()
        // Get image from base name without frame number or extension
        let file = documentsPath.appending("/wat")
        NSLog("\(file)")
        
        // Get animated image that you want to have each animation loop last 3 seconds
        let animatedImage = UIImage.animatedImageNamed(file, duration: 3)
        self.image.setImage(animatedImage)
        
        // Start animation from frame 0 and end at frame 360
        self.image.startAnimatingWithImages(in: NSRange.init(location: 0, length: 360), duration: 2, repeatCount: 5)
        
        // Uncomment to animate alpha
//        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
//            self.animate(withDuration: 0.5) {
//                self.image.setAlpha(0.0)
//            }
//        }

    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
