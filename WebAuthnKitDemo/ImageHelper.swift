//
//  ImageHelper.swift
//  WebAuthnKitDemo
//
//  Created by Lyo Kato on 2018/11/23.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import UIKit

class ImageHelper {
    
    private struct ClassProperty {
        static var backgroundLineImage: UIImage?
    }
    
    class var backgroundLineImage : UIImage {
        get {
            if ClassProperty.backgroundLineImage == nil {
                ClassProperty.backgroundLineImage =
                    ImageHelper.createHorizontalLine(
                        length: UIScreen.main.bounds.size.width,
                        lineWidth: 1,
                        color: UIColor.black
                    )
            }
            return ClassProperty.backgroundLineImage!
        }
    }
    
    class func releaseImageView(_ iv: UIImageView) {
        iv.image = nil
        iv.layer.sublayers = nil
    }
    
    class func createImage(_ width: CGFloat, _ height: CGFloat, drawing:((CGContext) -> Void)) -> UIImage {
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        let ctx = UIGraphicsGetCurrentContext()
        drawing(ctx!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
    
    class func createImageWithAutoScale(_ width: CGFloat, _ height: CGFloat, drawing:((CGContext) -> Void)) -> UIImage {
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let ctx = UIGraphicsGetCurrentContext()
        drawing(ctx!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
    
    class func crop(_ image: UIImage, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> UIImage {
        let rect = CGRect(x: x, y: y, width: w, height: h)
        let croppedRef = image.cgImage!.cropping(to: rect)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.translateBy(x: 0, y: rect.size.height)
        ctx?.scaleBy(x: 1.0, y: -1.0)
        ctx?.draw(croppedRef!, in: CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
    
    class func resizeWithAutoScale(_ image: UIImage, _ width: CGFloat, _ height: CGFloat) -> UIImage {
        return ImageHelper.createImageWithAutoScale(width, height) { ctx in
            ctx.interpolationQuality = .high
            ctx.setShouldAntialias(true)
            ctx.setAllowsAntialiasing(true)
            image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
    
    class func resize(_ image: UIImage, _ width: CGFloat, _ height: CGFloat) -> UIImage {
        return ImageHelper.createImage(width, height) { ctx in
            ctx.interpolationQuality = .high
            ctx.setShouldAntialias(true)
            ctx.setAllowsAntialiasing(true)
            image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
    
    class func createHorizontalLine(length: CGFloat, lineWidth: CGFloat, color: UIColor) -> UIImage {
        return ImageHelper.createImage(length, lineWidth) { ctx in
            ctx.setStrokeColor(color.cgColor)
            ctx.setLineWidth(lineWidth)
            ctx.setLineJoin(.miter)
            ctx.setLineCap(.square)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: lineWidth/2.0))
            path.addLine(to: CGPoint(x: length, y: lineWidth/2.0))
            ctx.addPath(path)
            ctx.strokePath()
        }
    }
    
}
