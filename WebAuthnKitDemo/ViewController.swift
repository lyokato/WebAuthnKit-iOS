//
//  ViewController.swift
//  WebAuthnKitDemo
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import UIKit
import WebAuthnKit
import PromiseKit

class ViewController: UIViewController {
    
    var webAuthnClient: WebAuthnClient!
    var userConsentUI: UserConsentUI!
    
    private func setupWebAuthnClient() {
        
        var authenticator = InternalAuthenticator(
            ui:            self.userConsentUI,
            encryptionKey: "hogehogehogehoge" // 16byte
        )
        
        self.webAuthnClient = WebAuthnClient(
            origin:        "https://example.org",
            authenticator: authenticator
        )
    }
    
    private func startRegistration() {
        
        var options = PublicKeyCredentialCreationOptions()
        options.challenge = "hogehoge"
        options.user.id = [0x00, 0x01, 0x02, 0x03]
        options.user.name = "john"
        options.user.displayName = "John"
        options.rp.id = "https://example.org"
        options.rp.name = "MyService"

        firstly {
            
            self.webAuthnClient.create(options)
            
            }.done { credential in
                
                var json = credential.toJSON()
            
            }.catch { error in
                
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.userConsentUI = UserConsentUI(viewController: self)
    }


}

