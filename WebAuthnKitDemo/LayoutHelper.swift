//
//  LayoutHelper.swift
//  WebAuthnKitDemo
//
//  Created by Lyo Kato on 2018/11/21.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    class func fromRGB(_ rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    class func fromRGBA(_ rgbValue: UInt, _ alpha: CGFloat) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(alpha)
        )
    }
}

extension UIView {
    
    
    func resize(_ w: CGFloat, _ h: CGFloat) {
        frame.size.width  = w
        frame.size.height = h
    }
    
    func width(_ w: CGFloat) {
        self.frame.size.width  = w
    }
    
    func height(_ h: CGFloat) {
        self.frame.size.height = h
    }
    
    func move(_ x: CGFloat, _ y: CGFloat) {
        self.frame.origin.x = x;
        self.frame.origin.y = y;
    }
    
    func left(_ x: CGFloat) {
        self.frame.origin.x = x;
    }
    
    func top(_ y: CGFloat) {
        self.frame.origin.y = y;
    }
    
    func moveBy(_ x: CGFloat, _ y: CGFloat) {
        self.frame.origin.x += x;
        self.frame.origin.y += y;
    }
    
    func fitScreenW(_ padding: CGFloat) {
        let bw = UIScreen.main.bounds.width
        self.frame.size.width = bw - padding * 2
    }
    
    func fitScreenH(_ padding: CGFloat) {
        let bh = UIScreen.main.bounds.height
        self.frame.size.height = bh - padding * 2
    }
    
    func fitParent(_ padding: CGFloat) {
        if let p = self.superview {
            self.frame.size.width = p.bounds.width - padding * 2
            self.frame.size.height = p.bounds.height - padding * 2
        }
    }
    
    func fitParentW(_ padding: CGFloat) {
        if let p = self.superview {
            self.frame.size.width = p.bounds.width - padding * 2
        }
    }
    
    func fitParentH(_ padding: CGFloat) {
        if let p = self.superview {
            self.frame.size.height = p.bounds.height - padding * 2
        }
    }
    
    func centerizeParentH() {
        if let p = self.superview {
            let pw = p.bounds.width
            let vw = self.frame.size.width
            self.frame.origin.x = (pw - vw) / 2.0
        }
    }
    
    func centerizeParentV() {
        if let p = self.superview {
            let ph = p.bounds.height
            let vh = self.frame.size.height
            self.frame.origin.y = (ph - vh) / 2.0
        }
    }
    
    func centerizeScreenH() {
        let bw = UIScreen.main.bounds.width
        let vw = self.frame.size.width
        self.frame.origin.x = (bw - vw) / 2.0
    }
    
    func centerizeScreenV() {
        let bh = UIScreen.main.bounds.height
        let vh = self.frame.size.height
        self.frame.origin.y = (bh - vh) / 2.0
    }
    
    func screenshot() -> Optional<UIImage> {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0.0)
        self.layer.render(in: UIGraphicsGetCurrentContext()!)
        let ss = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return ss
    }
}
