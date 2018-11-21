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
        
        self.userConsentUI = UserConsentUI(viewController: self)
        self.userConsentUI.
        
        var authenticator = InternalAuthenticator(
            ui:            self.userConsentUI,
            encryptionKey: Bytes.fromString("hogehogehogehoge") // 16byte
        )
        
        self.webAuthnClient = WebAuthnClient(
            origin:        "https://example.org",
            authenticator: authenticator
        )
    }
    
    private func startRegistration() {
        
        var options = PublicKeyCredentialCreationOptions()
        options.challenge = Bytes.fromString("hogehoge")
        
        options.user.id = Bytes.fromUInt64(12345)
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
        
    }


}

