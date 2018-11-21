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
            
        }.done { assertion in

            if let json = assertion.toJSON() {
                self.showResult(result: json)
            } else {
                self.showErrorPopup(WAKError.unknown)
            }

        }.catch { error in
                
            self.showErrorPopup(error)
        }
        
    }

    private func showErrorPopup(_ error: Error) {
        
        let alert = UIAlertController.init(
            title:          "ERROR",
            message:        "failed: \(error)",
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction.init(title: "OK", style: .default)
        alert.addAction(okAction)

        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        WAKLogger.available = true
        
        view.backgroundColor = UIColor.black
        self.view.addSubview(ViewCatalog.createBackground())
        self.navigationItem.title = "Authentication"
        
        self.setupTitleLabel()
        self.setupStartButton()
        self.setupWebAuthnClient()
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
        self.startAuthentication()
    }
    
    private func showResult(result: String) {
        //let vc = ResultViewController(result: result)
        //self.present(vc, animated: true, completion: nil)
    }
}
