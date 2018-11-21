//
//  AuthenticationViewController.swift
//  WebAuthnKitDemo
//
//  Created by Lyo Kato on 2018/11/21.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import UIKit
import WebAuthnKit
import PromiseKit
import CryptoSwift

class AuthenticationViewController: UIViewController {
    
    var webAuthnClient: WebAuthnClient!
    var userConsentUI: UserConsentUI!
    
    private func setupWebAuthnClient() {
        
        self.userConsentUI = UserConsentUI(viewController: self)
        
        // Registration Phase: These messages are shown for UserVerification/UserPresenceCheck popup.
        self.userConsentUI.confirmationPopupTitle = "Use Key"
        self.userConsentUI.confirmationPopupMessageBuilder = { rp, user in
            return "Create new key for \(user.displayName)?"
        }
        
        // Registration Phase: These messages are shown for confirmation popup when 'exclude' list is set.
        self.userConsentUI.newCredentialPopupTitle = "New Key"
        self.userConsentUI.newCredentialPopupMessage = "Create New Key for this service?"
        
        // Authentication Phase: These messages are shown for key-selection popup.
        self.userConsentUI.selectionPopupTitle = "Key Selection"
        self.userConsentUI.selectionPopupMessage = "Key Selection"
        
        let authenticator = InternalAuthenticator(
            ui:            self.userConsentUI,
            encryptionKey: Bytes.fromString("hogehogehogehoge") // 16byte
        )
        
        self.webAuthnClient = WebAuthnClient(
            origin:        "https://example.org",
            authenticator: authenticator
        )
    }
    
    private func startAuthentication() {
        
        var options = PublicKeyCredentialRequestOptions()
        options.challenge = Bytes.fromString("hogehoge")
        options.rpId = "https://example.org"
        options.userVerification = .required
        options.addAllowCredential(
            credentialId: Bytes.fromHex("01879de0"),
            transports:   [.internal_]
        )
        //options.timeout = UInt64(120)
        
        firstly {
            
            self.webAuthnClient.get(options)
            
            }.done { credential in
                
                var json = credential.toJSON()
                
            }.catch { error in
                
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        self.view.addSubview(ViewCatalog.createBackground())
        self.navigationItem.title = "Authentication"
        
        self.setupTitleLabel()
        self.setupStartButton()
    }
    
    private func setupTitleLabel() {
        let label = ViewCatalog.createLabel(text: "Authentication Process")
        label.height(30)
        label.fitScreenW(10)
        label.centerizeScreenH()
        label.top(120)
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = UIColor.white
        view.addSubview(label)
    }
    
    private func setupStartButton() {
        let button = ViewCatalog.createButton(text: "START")
        button.height(50)
        button.addTarget(self, action: #selector(type(of: self).onStartButtonTapped(_:)), for: .touchUpInside)
        button.fitScreenW(20)
        button.centerizeScreenH()
        button.top(250)
        
        button.layer.backgroundColor = UIColor.fromRGB(0xff4500).cgColor
        view.addSubview(button)
    }
    
    @objc func onStartButtonTapped(_ sender: UIButton) {
        let vc = ResultViewController(result: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
        self.present(vc, animated: true, completion: nil)
    }
}
