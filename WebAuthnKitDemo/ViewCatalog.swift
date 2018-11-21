//
//  ViewCatalog.swift
//  WebAuthnKitDemo
//
//  Created by Lyo Kato on 2018/11/21.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import UIKit


class ViewCatalog {
    
    class func createBackground() -> UIView
    {
        let colorTop = UIColor.fromRGB(0x00839e).cgColor
        let colorBottom = UIColor.fromRGB(0x000000).cgColor
        let gl = CAGradientLayer()
        gl.colors = [colorTop, colorBottom]
        gl.locations = [0.0, 1.0]
        let bg = UIView()
        bg.backgroundColor = UIColor.clear
        bg.layer.addSublayer(gl)
        bg.frame = UIScreen.main.bounds
        gl.frame = bg.frame
        
        return bg
    }
    
    class func createConfirmationAlert(title: String, _ message: String, _ actionName: String, _ handler: @escaping ((UIAlertAction) -> Void) ) -> UIAlertController {
        let alert = UIAlertController(
            title:   title,
            message: message,
            preferredStyle:  .alert)
        let action = UIAlertAction(title: actionName, style: .default, handler: handler)
        alert.addAction(action)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancel)
        return alert
    }
    
    class func createSimpleAlert(title: String, _ message: String) -> UIAlertController {
        let alert = UIAlertController(
            title:   title,
            message: message,
            preferredStyle:  .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        return alert
    }
    
    class func topPositionFor(from: UIViewController) -> CGFloat {
        let statusBarHeight = UIApplication.shared.statusBarFrame.size.height
        return (from.navigationController?.navigationBar.frame.size.height)! + statusBarHeight
    }
    
    class func createLabel(text: String) -> UILabel
    {
        let label = UILabel(frame: CGRect.zero)
        label.backgroundColor = UIColor.clear
        //label.layer.masksToBounds = true
        //label.layer.cornerRadius = 10.0
        label.text = text;
        label.textAlignment = .center
        return label
    }
    
    class func createTextField(placeholder: String,
                               leftPadding: CGFloat, height: CGFloat) -> UITextField
    {
        let field = UITextField(frame: CGRect.zero)
        field.borderStyle = .none
        field.layer.cornerRadius = 10.0
        field.layer.masksToBounds = true
        field.layer.backgroundColor = UIColor.white.cgColor
        field.placeholder = placeholder
        field.text = ""
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: leftPadding, height: height))
        field.leftView = paddingView
        field.leftViewMode = .always
        return field
    }
    
    class func createTextView() -> UITextView
    {
        let view = UITextView(frame: CGRect.zero)
        return view
    }
    
    class func createButton(text: String) ->  UIButton
    {
        let button = UIButton()
        button.setTitle(text, for: .normal)
        //button.layer.backgroundColor = UIColor.fromRGB(0x008b8b).CGColor
        button.layer.backgroundColor = UIColor.fromRGB(0x87ceeb).cgColor
        button.layer.cornerRadius = 25.0
        button.titleLabel?.textColor = UIColor.white
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.bold)
        return button
    }
    
    
}
