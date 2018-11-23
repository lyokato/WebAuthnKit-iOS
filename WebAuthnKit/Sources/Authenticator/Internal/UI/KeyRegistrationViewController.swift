//
//  KeyRegistrationViewController.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/22.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import UIKit
import PromiseKit

public enum ResidentKeyDuplicationPolicy {
    case allow
    case overwrite
    case ask
}

public protocol KeyDetailViewDelegate {
    func userDidRequestToCreateNewKey(keyName: String)
    func userDidRequestToOverwriteKey(keyName: String)
    func userDidCancel()
}

class KeyDetailView: UIView, UITextFieldDelegate {
    
    var delegate: KeyDetailViewDelegate?
    
    let user: PublicKeyCredentialUserEntity
    let rp:   PublicKeyCredentialRpEntity
    
    let askUserDuplicationHandling: Bool
    let showRpInformation:          Bool
    
    var keyNameField: UITextField!
    
    init(
        user: PublicKeyCredentialUserEntity,
        rp:   PublicKeyCredentialRpEntity,
        askUserDuplicationHandling: Bool,
        showRpInformation:          Bool
    ) {
        
        self.user = user
        self.rp   = rp
        
        self.askUserDuplicationHandling = askUserDuplicationHandling
        self.showRpInformation          = showRpInformation
        
        super.init(frame: CGRect.zero)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func downloadImage(imageView:UIImageView, url: URL) {
        URLSession.shared.dataTask(with: URLRequest(url: url)) { (data, response, error) in
            guard let data = data, let _ = response, error == nil else {
                return
            }
            DispatchQueue.main.async(execute: {
                imageView.image = UIImage(data: data)
            })
        }.resume()
    }
    
    private func rgbColor(_ rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    private func setup() {
        
        //self.backgroundColor = self.rgbColor(0xf0f0f0)
        
        let effect = UIBlurEffect(style: .prominent)
        let backgroundView = UIVisualEffectView(effect: effect)
        self.addSubview(backgroundView)
        
        self.layer.cornerRadius = 10.0
        self.clipsToBounds = true
        
        let verticalMargin: CGFloat  = 20
        let horizontalMargin: CGFloat = 50
        
        let rpIconSize: CGFloat = 25
        let userIconSize: CGFloat = 75
        
        let minWidth: CGFloat = 700
        var viewWidth: CGFloat = UIScreen.main.bounds.width - horizontalMargin * 2
        viewWidth = min(minWidth, viewWidth)
        
        var offset: CGFloat =  verticalMargin
        
        let wideLabelMargin: CGFloat = 10
        
        let titleHeight: CGFloat = 20
        let titleLabel = UILabel(frame: CGRect.zero)
        titleLabel.frame = CGRect(
            x: wideLabelMargin,
            y: offset,
            width: viewWidth - wideLabelMargin * 2,
            height: titleHeight
        )
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.black
        titleLabel.text = "New Login Key"
        titleLabel.font = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel)
        
        offset = offset + titleHeight + 16
        
        let keyNameFieldHeight: CGFloat = 30

        self.keyNameField = UITextField(frame: CGRect.zero)
        keyNameField.frame = CGRect(
            x: 20,
            //y: keyNameMargin * 2 + keyNameLabelHeight,
            y: offset,
            width: viewWidth - 40,
            height: keyNameFieldHeight
        )
        self.keyNameField.borderStyle = .none
        self.keyNameField.delegate = self
        self.keyNameField.layer.backgroundColor = UIColor.white.cgColor
        self.keyNameField.layer.borderColor = self.rgbColor(0xbbbbbb).cgColor
        self.keyNameField.layer.cornerRadius = 5.0
        self.keyNameField.text = self.createDefaultKeyName()
        self.keyNameField.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        self.addSubview(self.keyNameField)
        
        offset = offset + keyNameFieldHeight + 16
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: keyNameFieldHeight))
        self.keyNameField.leftView = paddingView
        self.keyNameField.leftViewMode = .always

        if let iconURLString = self.user.icon {
            if let iconURL = URL(string: iconURLString) {
                let userIconframe = CGRect(
                    x: (viewWidth - userIconSize) / 2,
                    y: offset,
                    width:  userIconSize,
                    height: userIconSize
                )
                let userIconView = UIImageView(frame: userIconframe)
                userIconView.layer.cornerRadius = userIconSize / 2
                userIconView.clipsToBounds = true
                self.addSubview(userIconView)
                self.downloadImage(imageView: userIconView, url: iconURL)
                
                if let iconURLString = self.rp.icon {
                    if let iconURL = URL(string: iconURLString) {
                        
                        let rpIconFrame = CGRect(
                            x: ((viewWidth - userIconSize) / 2) + userIconSize - rpIconSize,
                            y: offset + userIconSize - rpIconSize,
                            width:  rpIconSize,
                            height: rpIconSize
                        )
                        
                        let rpIconView = UIImageView(frame: rpIconFrame)
                        rpIconView.layer.cornerRadius = rpIconSize / 2.0
                        rpIconView.clipsToBounds = true
                        self.addSubview(rpIconView)
                        self.downloadImage(imageView: rpIconView, url: iconURL)
                        
                    } else {
                        WAKLogger.debug("<KeyDetailView> rp.icon is not a valid URL: \(iconURLString)")
                    }
                }
                
                offset = offset + userIconSize + 10
            } else {
                WAKLogger.debug("<KeyDetailView> user.icon is not a valid URL: \(iconURLString)")
            }
        }

        let displayNameHeight: CGFloat = 20
        let displayNameLabel = UILabel(frame: CGRect.zero)
        displayNameLabel.frame = CGRect(
            x: wideLabelMargin,
            y: offset,
            width: viewWidth - wideLabelMargin * 2,
            height: displayNameHeight
        )
        displayNameLabel.backgroundColor = UIColor.clear
        displayNameLabel.text = self.user.displayName
        displayNameLabel.textAlignment = .center
        displayNameLabel.font = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        self.addSubview(displayNameLabel)
        
        offset = offset + displayNameHeight + 10
        
        if self.showRpInformation {
            
            let rpMargin: CGFloat = 10
            
            let rpNameLabel = UILabel(frame: CGRect.zero)
            
            rpNameLabel.frame = CGRect(
                x: rpMargin,
                y: offset,
                width: viewWidth - rpMargin * 2,
                height: 20
            )
            
            rpNameLabel.backgroundColor = UIColor.clear
            rpNameLabel.text = "[ " + self.rp.name + " ]"
            rpNameLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
            rpNameLabel.textAlignment = .center
            
            self.addSubview(rpNameLabel)
            
            offset = offset + rpIconSize + 10
        }

        
        if self.askUserDuplicationHandling {
            // label: you already have key for this service & user, are you sure to create new key?
            // buttons: [Cancel] [Overwrite] [Create]
        } else {
            
            let buttonMargin: CGFloat = 0
            let buttonWidth = (viewWidth - buttonMargin * 3) / 2.0
            let buttonHeight: CGFloat = 50
            let cancelButton = UIButton()
            
            cancelButton.frame = CGRect(
                x: buttonMargin,
                y: offset,
                width: buttonWidth + 1,
                height: buttonHeight
            )
            cancelButton.setTitle("Cancel", for: .normal)
            cancelButton.setTitleColor(UIColor.red, for: .normal)
            //cancelButton.layer.backgroundColor = UIColor.white.cgColor
            cancelButton.layer.borderColor = self.rgbColor(0xbbbbbb).cgColor
            cancelButton.layer.borderWidth = 1.0
            cancelButton.titleLabel?.textColor = self.tintColor
            cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .light)
            cancelButton.addTarget(
                self,
                action: #selector(KeyDetailView.onCancelButtonTapped(_:)),
                for: .touchUpInside
            )
            self.addSubview(cancelButton)

            let createButton = UIButton()
            createButton.frame = CGRect(
                x: buttonMargin * 2 + buttonWidth,
                y: offset,
                width: buttonWidth,
                height: buttonHeight
            )
            createButton.setTitleColor(UIColor.blue, for: .normal)
            createButton.setTitle("Create", for: .normal)
            //createButton.layer.backgroundColor = UIColor.white.cgColor
            createButton.layer.borderColor = self.rgbColor(0xbbbbbb).cgColor
            createButton.layer.borderWidth = 1.0
            createButton.titleLabel?.textColor = self.tintColor
            createButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
            createButton.addTarget(
                self,
                action: #selector(KeyDetailView.onCreateButtonTapped(_:)),
                for: .touchUpInside
            )
            self.addSubview(createButton)
            
            offset = offset + buttonHeight
        }
        
        self.frame = CGRect(
            x: 0,
            y: 0,
            width: viewWidth,
            height: offset
        )
        
        self.layer.borderColor = self.rgbColor(0xdddddd).cgColor
        self.layer.borderWidth = 1
        backgroundView.frame = self.frame

    }
    
    private func createDefaultKeyName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmm"
        let dateString = formatter.string(from: Date())
        return "\(self.user.displayName) (\(dateString))"
    }
    
    private func getCurrentKeyName() -> String {
        if let keyName = self.keyNameField.text {
            return keyName.isEmpty ? self.user.displayName : keyName
        } else {
            return self.createDefaultKeyName()
        }
    }
    
    @objc func onCancelButtonTapped(_ sender: UIButton) {
        if self.keyNameField.isFirstResponder {
            self.keyNameField.resignFirstResponder()
        }
        self.delegate?.userDidCancel()
    }
    
    @objc func onCreateButtonTapped(_ sender: UIButton) {
        if self.keyNameField.isFirstResponder {
            self.keyNameField.resignFirstResponder()
        }
        self.delegate?.userDidRequestToCreateNewKey(keyName: self.getCurrentKeyName())
    }

    @objc func onOverwriteButtonTapped(_ sender: UIButton) {
        if self.keyNameField.isFirstResponder {
            self.keyNameField.resignFirstResponder()
        }
        self.delegate?.userDidRequestToOverwriteKey(keyName: self.getCurrentKeyName())
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.keyNameField.isFirstResponder {
            self.keyNameField.resignFirstResponder()
        }
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}

public class KeyRegistrationViewController : UIViewController, KeyDetailViewDelegate {
    
    let resolver: Resolver<(Bool, String)>
    let user: PublicKeyCredentialUserEntity
    let rp: PublicKeyCredentialRpEntity
    
    let askUserDuplicationHandling: Bool
    let showRpInformation: Bool
    
    init(
        resolver: Resolver<(Bool, String)>,
        user: PublicKeyCredentialUserEntity,
        rp: PublicKeyCredentialRpEntity,
        askUserDuplicationHandling: Bool,
        showRpInformation: Bool
    ) {
        
        self.resolver = resolver
        self.user = user
        self.rp = rp
        
        self.askUserDuplicationHandling = askUserDuplicationHandling
        self.showRpInformation = showRpInformation
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overCurrentContext
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var detailView: KeyDetailView!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.clear

        self.detailView = KeyDetailView(
            user: self.user,
            rp: self.rp,
            askUserDuplicationHandling: self.askUserDuplicationHandling,
            showRpInformation: self.showRpInformation
        )
        self.detailView.delegate = self
        self.view.addSubview(self.detailView)
        var detailViewFrame = self.detailView.frame
        detailViewFrame.origin.x = (self.view.frame.width - detailViewFrame.width) / 2.0
        detailViewFrame.origin.y = (self.view.frame.height - detailViewFrame.height) / 2.0
        self.detailView.frame = detailViewFrame
    }
    
    public func userDidCancel() {
        dismiss(animated: true) {
           self.resolver.reject(WAKError.cancelled)
        }
    }
    
    public func userDidRequestToOverwriteKey(keyName: String) {
        dismiss(animated: true) {
           self.resolver.fulfill((true, keyName))
        }
    }
    
    public func userDidRequestToCreateNewKey(keyName: String) {
        dismiss(animated: true) {
           self.resolver.fulfill((false, keyName))
        }
    }
    
}
