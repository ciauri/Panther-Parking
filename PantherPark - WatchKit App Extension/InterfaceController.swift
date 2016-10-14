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
    
    var documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!


    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        

    }
    
    fileprivate func generateRingImageSequence(withRadius radius: Int, numberOfFrames frames: Int) -> [UIImage] {
        
        let imageLength = 202
        let size = CGSize(width: imageLength, height: imageLength)
        let opaque = false
        let point = CGPoint(x: imageLength/2, y: imageLength/2)
        let intervals = 2*CGFloat.pi/CGFloat(frames)
        let lineWidth = CGFloat(imageLength/10)
//        let radius = CGFloat(imageLength/2)-lineWidth
        
        var imageArray: [UIImage] = []
        
        
        
        var previousImage: UIImage?
        
        for centerX in 0...frames {
            UIGraphicsBeginImageContextWithOptions(size, opaque, 0.0)
            let context = UIGraphicsGetCurrentContext()
            let percent = Double(Double(centerX)/Double(frames))
            let startAngle = CGFloat(centerX-1)*intervals
            let endAngle = CGFloat(centerX)*intervals
            //            context?.setLineWidth(5)
            context?.setStrokeColor(UIColor.temperatureColor(fromPercentCompletion: Float(percent)).cgColor)
            
            let k = UIBezierPath(arcCenter: point, radius: CGFloat(radius), startAngle: startAngle, endAngle: endAngle, clockwise: true)
            k.lineCapStyle = .round
            k.lineWidth = lineWidth
            k.stroke()

            // Snapshot generated image
            let image = UIGraphicsGetImageFromCurrentImageContext()
            
            // If a previous image exists, layer it on top of the previous image
            if let previousImage = previousImage {
                previousImage.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
                image?.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height), blendMode: .normal, alpha: 1.0)
            }
            
            // Snapshot merged image
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            guard let validImage = newImage
                else {
                    NSLog("Image not able to be created")
                    continue
            }
            
            imageArray.append(validImage)
            previousImage = validImage
            
        }
        
        return imageArray
    }
    

    
    func combine(image: UIImage, onTopOf bottomImage: UIImage) -> UIImage {
        let size = CGSize(width: max(image.size.width, bottomImage.size.width), height: max(image.size.height, bottomImage.size.height))
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        bottomImage.draw(at: CGPoint(x: 0, y: 0))
        image.draw(at: CGPoint(x: 0, y: 0))
        let combinedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return combinedImage
    }
    
    func combine(images: [UIImage], onTopOf bottomImages: [UIImage]) -> [UIImage] {
        guard images.count == bottomImages.count
            else {
                return []
        }
        var combinedImages: [UIImage] = []
        for (index,image) in images.enumerated() {
            combinedImages.append(combine(image: image, onTopOf: bottomImages[index]))
        }
        return combinedImages
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didAppear() {
        super.didAppear()
        // Get image from base name without frame number or extension
        let file = documentsPath.appendingPathComponent("Rings")
        NSLog("\(file)")
        
        if let rings = NSKeyedUnarchiver.unarchiveObject(withFile: file.path) as? [UIImage] {
            let animatedImage = UIImage.animatedImage(with: rings, duration: 60)
            self.image.setImage(animatedImage)
        } else {
            // Get animated image that you want to have each animation loop last 3 seconds
            //        let animatedImage = UIImage.animatedImageNamed(file, duration: 3)
            let bigRing = generateRingImageSequence(withRadius: 90, numberOfFrames: 360)
            let smallRing = generateRingImageSequence(withRadius: 65, numberOfFrames: 360)
            let smallerRing = generateRingImageSequence(withRadius: 40, numberOfFrames: 360)
            let smallestRing = generateRingImageSequence(withRadius: 15, numberOfFrames: 360)
            
            
            let combinedImages = combine(images: smallRing, onTopOf: bigRing)
            let combinedImages2 = combine(images: combinedImages, onTopOf: smallerRing)
            let combinedImages3 = combine(images: combinedImages2, onTopOf: smallestRing)
            
            //        let images = bigRing + smallRing
            //        let images = generateRingImageSequence(withWidth: 50, numberOfFrames: 300)
            
            
            let animatedImage = UIImage.animatedImage(with: combinedImages3, duration: 60)
            
            save(images: combinedImages3)
            
            
            self.image.setImage(animatedImage)
        }
        
        

        
        // Start animation from frame 0 and end at frame 360
        self.image.startAnimatingWithImages(in: NSRange.init(location: 0, length: 360), duration: 30, repeatCount: 5)
        
        // Uncomment to animate alpha
//        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
//            self.animate(withDuration: 0.5) {
//                self.image.setAlpha(0.0)
//            }
//        }

    }
    
    func save(images: [UIImage]) {
        // Create file path
        // Animated images follow the naming convention `imageNameX.png` where X is the frame number
        //        let file = documentsPath.appending("/wat\(centerX).png")
        
        let url = documentsPath.appendingPathComponent("Rings")
        NSKeyedArchiver.archiveRootObject(images, toFile: url.path)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
