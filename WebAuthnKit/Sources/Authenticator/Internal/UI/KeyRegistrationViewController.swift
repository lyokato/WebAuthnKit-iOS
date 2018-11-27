//
//  KeyRegistrationViewController.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/22.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import UIKit
import PromiseKit

public protocol KeyDetailViewDelegate: class {
    func userDidRequestToCreateNewKey(keyName: String)
    func userDidCancel()
}

class KeyDetailView: UIView, UITextFieldDelegate {
    
    weak var delegate: KeyDetailViewDelegate?
    
    private let config: UserConsentUIConfig
    private let user: PublicKeyCredentialUserEntity
    private let rp:   PublicKeyCredentialRpEntity
    
    private var keyNameField: UITextField!
    
    init(
        config: UserConsentUIConfig,
        user: PublicKeyCredentialUserEntity,
        rp: PublicKeyCredentialRpEntity
    ) {
        
        self.config = config
        self.user = user
        self.rp   = rp
        
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
        
        let minWidth: CGFloat = 320
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
        titleLabel.text = self.config.keyCreationTitle
        titleLabel.font = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel)
        
        offset = offset + titleHeight + 12
        
        let keyNameFieldHeight: CGFloat = 30

        self.keyNameField = UITextField(frame: CGRect.zero)
        keyNameField.frame = CGRect(
            x: 20,
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
        
        offset = offset + keyNameFieldHeight + 18
        
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
                
                offset = offset + userIconSize + 14
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
        
        offset = offset + displayNameHeight + 6
        
        if self.config.showRPInformation {
            
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
        cancelButton.setTitle(self.config.keyCreationCancelButtonText, for: .normal)
        cancelButton.setTitleColor(self.tintColor, for: .normal)
        cancelButton.layer.borderColor = self.rgbColor(0xbbbbbb).cgColor
        cancelButton.layer.borderWidth = 1.0
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
        createButton.setTitleColor(self.tintColor, for: .normal)
        createButton.setTitle(self.config.keyCreationCreateButtonText, for: .normal)
        createButton.layer.borderColor = self.rgbColor(0xbbbbbb).cgColor
        createButton.layer.borderWidth = 1.0
        createButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
        createButton.addTarget(
            self,
            action: #selector(KeyDetailView.onCreateButtonTapped(_:)),
            for: .touchUpInside
        )
        self.addSubview(createButton)

        offset = offset + buttonHeight

        self.frame = CGRect(
            x: 0,
            y: 0,
            width: viewWidth,
            height: offset
        )
        
        self.layer.borderColor = self.rgbColor(0xdddddd).cgColor
        self.layer.borderWidth = 1
        backgroundView.frame = self.frame

        WAKLogger.debug("<KeyDetailView> frame:\(viewWidth):\(offset)")
    }
    
    private func createDefaultKeyName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: Date())
        return "\(self.user.name) (\(dateString))"
    }
    
    private func getCurrentKeyName() -> String {
        if let keyName = self.keyNameField.text {
            return keyName.isEmpty ? self.createDefaultKeyName() : keyName
        } else {
            return self.createDefaultKeyName()
        }
    }
    
    @objc func onCancelButtonTapped(_ sender: UIButton) {
        self.resignKeyNameField()
        self.delegate?.userDidCancel()
    }
    
    @objc func onCreateButtonTapped(_ sender: UIButton) {
        self.resignKeyNameField()
        self.delegate?.userDidRequestToCreateNewKey(keyName: self.getCurrentKeyName())
    }
    
    func resignKeyNameField() {
        self.keyNameField.resignFirstResponder()
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.resignKeyNameField()
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}

public class KeyRegistrationViewController : UIViewController,
    KeyDetailViewDelegate {
    
    public weak var delegate: UserConsentViewControllerDelegate?
    
    private let resolver: Resolver<String>
    private let config: UserConsentUIConfig
    private let user: PublicKeyCredentialUserEntity
    private let rp: PublicKeyCredentialRpEntity
    
    init(
        resolver: Resolver<String>,
        config: UserConsentUIConfig,
        user: PublicKeyCredentialUserEntity,
        rp: PublicKeyCredentialRpEntity
    ) {
        
        self.resolver = resolver
        self.config = config
        self.user = user
        self.rp = rp
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
            config: self.config,
            user: self.user,
            rp: self.rp
        )
        self.detailView.delegate = self
        self.view.addSubview(self.detailView)
        var detailViewFrame = self.detailView.frame
        detailViewFrame.origin.x = (self.view.frame.width - detailViewFrame.width) / 2.0
        detailViewFrame.origin.y = (self.view.frame.height - detailViewFrame.height) / 2.0
        self.detailView.frame = detailViewFrame
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(type(of: self).onBackgroundViewTapped(_:)))
        self.view.addGestureRecognizer(gesture)
    }
    
    public func userDidCancel() {
        self.delegate?.consentViewControllerWillDismiss(viewController: self)
        dismiss(animated: true) {
           self.resolver.reject(WAKError.cancelled)
        }
    }
    
    @objc public func onBackgroundViewTapped(_ sender: UITapGestureRecognizer) {
        self.detailView.resignKeyNameField()
    }
    
    public func userDidRequestToCreateNewKey(keyName: String) {
        self.delegate?.consentViewControllerWillDismiss(viewController: self)
        dismiss(animated: true) {
           self.resolver.fulfill(keyName)
        }
    }
    
}
