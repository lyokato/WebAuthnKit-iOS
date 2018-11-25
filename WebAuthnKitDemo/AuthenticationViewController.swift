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

class AuthenticationViewController: UIViewController, UITextFieldDelegate {
    
    var webAuthnClient: WebAuthnClient!
    var userConsentUI: UserConsentUI!
    
    private func setupWebAuthnClient() {
        
        self.userConsentUI = UserConsentUI(viewController: self)
        self.userConsentUI.config.alwaysShowKeySelection = true

        let authenticator = InternalAuthenticator(ui: self.userConsentUI)
        
        self.webAuthnClient = WebAuthnClient(
            origin:        "https://example.org",
            authenticator: authenticator
        )
    }
    
    private func startAuthentication() {
        
        guard let challenge = self.challengeText.text else {
            self.showErrorPopup(FormError.missing("challenge"))
            return
        }
        
        if challenge.isEmpty {
            self.showErrorPopup(FormError.empty("challenge"))
            return
        }
        
        guard let rpId = self.rpIdText.text else {
            self.showErrorPopup(FormError.missing("rpId"))
            return
        }
        
        if rpId.isEmpty {
            self.showErrorPopup(FormError.empty("rpId"))
            return
        }
        
        let verification = [
            UserVerificationRequirement.required,
            UserVerificationRequirement.preferred,
            UserVerificationRequirement.discouraged
        ][self.userVerification.selectedSegmentIndex]
        
        var options = PublicKeyCredentialRequestOptions()
        options.challenge = Bytes.fromHex(challenge)
        options.rpId = rpId
        options.userVerification = verification
        
        if let credId = self.credentialIdText.text {
            if !credId.isEmpty {
                options.addAllowCredential(
                    credentialId: Bytes.fromHex(credId),
                    transports:   [.internal_]
                )
            }
        }
        //options.timeout = UInt64(120)
        
        print("==========================================")
        print("challenge: " + Base64.encodeBase64URL(options.challenge))
        print("==========================================")

        firstly {
            
            self.webAuthnClient.get(options)
            
        }.done { assertion in
            
            print("==========================================")
            print("credentialId: " + assertion.id)
            print("rawId: " + Base64.encodeBase64URL(assertion.rawId))
            print("authenticatorData: " + Base64.encodeBase64URL(assertion.response.authenticatorData))
            print("signature: " + Base64.encodeBase64URL(assertion.response.signature))
            print("userHandle: " + Base64.encodeBase64URL(assertion.response.userHandle!))
            print("clientDataJSON: " + Base64.encodeBase64URL(assertion.response.clientDataJSON.data(using: .utf8)!))
            print("==========================================")

            self.showResult(assertion)

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
    
    var credentialIdText: UITextField!
    var rpIdText:         UITextField!
    var challengeText:    UITextField!
    var userVerification: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        WAKLogger.available = true
        
        view.backgroundColor = UIColor.black
        self.view.addSubview(ViewCatalog.createBackground())
        self.navigationItem.title = "Authentication"

        var offset: CGFloat = 100
        
        self.newLabel(text: "Relying Party Id", top: offset)
        self.rpIdText = self.newTextField(height: 30, top: offset + 30, text: "https://example.org")

        offset = offset + 70
        
        self.newLabel(text: "Challenge (Hex)", top: offset)
        self.challengeText = self.newTextField(height: 30, top: offset + 30, text: "aed9c789543b")
        
        offset = offset + 70
        
        self.newLabel(text: "User Verification", top: offset)
        self.userVerification = self.newSegmentedControl(top: offset + 30, list: ["Required", "Preferred", "Discouraged"])
        
        offset = offset + 70
        
        self.newLabel(text: "Credential Id (Hex) (Optional)", top: offset)
        self.credentialIdText = self.newTextField(height: 30, top: offset + 30, text: "")
        

        self.setupWebAuthnClient()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(AuthenticationViewController.onStartButtonTapped))
    }
    
    private func newLabel(text: String, top: CGFloat) {
        let label = ViewCatalog.createLabel(text: text)
        label.height(20)
        label.fitScreenW(10)
        label.centerizeScreenH()
        label.top(top)
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = UIColor.white
        view.addSubview(label)
    }
    
    private func newSegmentedControl(top: CGFloat, list: [String]) -> UISegmentedControl {
        let seg = UISegmentedControl(items: list)
        seg.fitScreenW(20)
        seg.selectedSegmentIndex = 0
        seg.top(top)
        seg.tintColor = UIColor.fromRGB(0xff8c00)
        seg.backgroundColor = UIColor.black
        view.addSubview(seg)
        seg.centerizeScreenH()
        return seg
    }
    
    private func newTextField(height: CGFloat, top: CGFloat, text: String) -> UITextField {
        let view = ViewCatalog.createTextField(placeholder: "", leftPadding: 10, height: height)
        view.text = text
        view.fitScreenW(20)
        view.height(height)
        view.layer.cornerRadius = 5.0
        view.top(top)
        view.delegate = self
        view.autocorrectionType = .no
        view.autocapitalizationType = .none
        view.backgroundColor = UIColor.white
        view.textColor = UIColor.black
        view.delegate = self
        self.view.addSubview(view)
        view.centerizeScreenH()
        view.font = UIFont.systemFont(ofSize: 12)
        return view
    }
    
    @objc func onStartButtonTapped(_ sender: UIButton) {
        self.startAuthentication()
    }
    
    private func showResult(_ result: WebAuthnClient.GetResponse) {
        
        let user: [UInt8] = result.response.userHandle ?? []
        let userName = String(data: Data(bytes: user), encoding: .utf8) ?? ""
        
        let vc = ResultViewController(
            rawId:             result.rawId.toHexString(),
            credId:            result.id,
            clientDataJSON:    result.response.clientDataJSON,
            authenticatorData: Base64.encodeBase64URL(result.response.authenticatorData),
            signature:         result.response.signature.toHexString(),
            userHandle:        userName
        )
        
        self.present(vc, animated: true, completion: nil)
        
    }
    
    private func resignAllTextViews() {
        [
            rpIdText,
            challengeText,
            credentialIdText
            ].forEach { textField in
                if let tf = textField {
                    if tf.isFirstResponder {
                        tf.resignFirstResponder()
                    }
                }
        }
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.resignAllTextViews()
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
