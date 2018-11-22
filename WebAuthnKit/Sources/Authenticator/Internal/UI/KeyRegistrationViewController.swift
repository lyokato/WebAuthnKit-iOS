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
    case override
    case ask
}

public protocol KeyDetailViewDelegate {
    func userDidRequestToCreateNewKey(keyName: String)
    func userDidRequestToOverrideKey(keyName: String)
    func userDidCancel()
}

public class KeyDetailView: UIView {
    
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
    
    private func setup() {
        
        var offset: CGFloat = 0
        
        // RP part
        
        if self.showRpInformation {
            
            if let iconURLString = self.rp.icon {
                if let iconURL = URL(string: iconURLString) {
                    let rpIconFrame = CGRect(x: 10, y: offset + 10, width: 50, height: 50)
                    let rpIconView = UIImageView(frame: rpIconFrame)
                    rpIconView.layer.cornerRadius = 50
                    rpIconView.clipsToBounds = true
                    self.addSubview(rpIconView)
                    self.downloadImage(imageView: rpIconView, url: iconURL)
                } else {
                    WAKLogger.debug("<KeyDetailView> rp.icon is not a valid URL: \(iconURLString)")
                }
            }
            
            let rpNameLabel = UILabel(frame: CGRect.zero)
            rpNameLabel.backgroundColor = UIColor.clear
            rpNameLabel.text = self.rp.name;
            rpNameLabel.textAlignment = .left
            
            self.addSubview(rpNameLabel)

            offset = 100
        }
        
        // User part
        
        if let iconURLString = self.user.icon {
            if let iconURL = URL(string: iconURLString) {
                let userIconframe = CGRect(x: 10, y: offset + 10, width: 100, height: 100)
                let userIconView = UIImageView(frame: userIconframe)
                userIconView.layer.cornerRadius = 50
                userIconView.clipsToBounds = true
                self.addSubview(userIconView)
                self.downloadImage(imageView: userIconView, url: iconURL)
            } else {
                WAKLogger.debug("<KeyDetailView> user.icon is not a valid URL: \(iconURLString)")
            }
        }
        
        // - id
        // - name
        // - displayName
        
        self.keyNameField = UITextField(frame: CGRect.zero)
        self.keyNameField.borderStyle = .none
        self.keyNameField.layer.backgroundColor = UIColor.white.cgColor
        self.keyNameField.text = self.user.displayName
        /*
         let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: leftPadding, height: height))
         self.keyNameField.leftView = paddingView
         self.keyNameField.leftViewMode = .always
         */
        
        self.addSubview(self.keyNameField)

        if self.askUserDuplicationHandling {
            // label: you already have key for this service & user, are you sure to create new key?
            // buttons: [Cancel] [Override] [Create]
        } else {
            // buttons: [Cancel] [Create]
        }

    }
    
    private func getCurrentKeyName() -> String {
        if let keyName = self.keyNameField.text {
            return keyName.isEmpty ? self.user.displayName : keyName
        } else {
            return self.user.displayName
        }
    }
    
    @objc func onCancelButtonTapped(sender: UIButton) {
        self.delegate?.userDidCancel()
    }
    
    @objc func onCreateButtonTapped(sender: UIButton) {
        self.delegate?.userDidRequestToCreateNewKey(keyName: self.getCurrentKeyName())
    }

    @objc func onOverrideButtonTapped(sender: UIButton) {
        self.delegate?.userDidRequestToOverrideKey(keyName: self.getCurrentKeyName())
    }

}

public class KeyRegistrationViewController : UIViewController, KeyDetailViewDelegate {
    
    let resolver: Resolver<(Bool, String)>
    let user:     PublicKeyCredentialUserEntity
    let rp:       PublicKeyCredentialRpEntity
    
    let askUserDuplicationHandling: Bool
    let showRpInformation:          Bool
    
    init(
        resolver: Resolver<(Bool, String)>,
        user:     PublicKeyCredentialUserEntity,
        rp:       PublicKeyCredentialRpEntity,
        askUserDuplicationHandling: Bool,
        showRpInformation:          Bool
    ) {
        
        self.resolver = resolver
        self.user     = user
        self.rp       = rp
        
        self.askUserDuplicationHandling = askUserDuplicationHandling
        self.showRpInformation          = showRpInformation
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        
    }
    
    public func userDidCancel() {
        dismiss(animated: true) {
           self.resolver.reject(WAKError.cancelled)
        }
    }
    
    public func userDidRequestToOverrideKey(keyName: String) {
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
