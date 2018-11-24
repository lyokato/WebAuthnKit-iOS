//
//  ResultViewController.swift
//  WebAuthnKitDemo
//
//  Created by Lyo Kato on 2018/11/21.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import UIKit
import WebAuthnKit
import PromiseKit
import CryptoSwift

class ResultViewController: UIViewController, UITextFieldDelegate {
    
    var rawId: String
    var credId: String
    var clientDataJSON: String
    var attestationObject: String
    
    var authenticatorData: String
    var signature: String
    var userHandle: String
    
    init(
        rawId: String,
        credId: String,
        clientDataJSON: String,
        authenticatorData: String,
        signature: String,
        userHandle: String
        ) {
        self.rawId = rawId
        self.credId = credId
        self.clientDataJSON = clientDataJSON
        self.attestationObject = ""
        self.authenticatorData = authenticatorData
        self.signature = signature
        self.userHandle = userHandle
        super.init(nibName: nil, bundle: nil)
    }
    
    init(
        rawId: String,
        credId: String,
        clientDataJSON: String,
        attestationObject: String
    ) {
        self.rawId = rawId
        self.credId = credId
        self.clientDataJSON = clientDataJSON
        self.attestationObject = attestationObject
        self.authenticatorData = ""
        self.signature = ""
        self.userHandle = ""
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var rawIdText: UITextField?
    var credIdText: UITextField?
    var userHandleText: UITextField?
    
    var clientDataJSONText: UITextView?
    var attestationObjectText: UITextView?
    var authenticatorDataText: UITextView?
    var signatureText: UITextView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        self.view.addSubview(ViewCatalog.createBackground())
        self.navigationItem.title = "Result"
        
        self.newLabel(text: "Raw Id (Hex)", top: 60)
        self.rawIdText = self.newTextField(height: 30, top: 90, text: self.rawId)
        self.newLabel(text: "Credential Id (Base64URL)", top: 130)
        self.credIdText = self.newTextField(height: 30, top: 160, text: self.credId)
        self.newLabel(text: "Client Data JSON", top: 200)
        self.clientDataJSONText = self.newTextView(height: 50, top: 230, text: self.clientDataJSON)
        
        if self.signature.isEmpty {
            self.newLabel(text: "Attestation Object (Base64URL)", top: 290)
            self.attestationObjectText =
                self.newTextView(height: 200, top: 320, text: self.attestationObject)
        } else {
            WAKLogger.debug("SIGNATURE_SIZE: \(self.signature.count)")
            self.newLabel(text: "Authenticator Data (Base64URL)", top: 290)
            self.authenticatorDataText =
                self.newTextView(height: 50, top: 320, text: self.authenticatorData)
            self.newLabel(text: "Signature (Hex)", top: 380)
            self.signatureText = self.newTextView(height: 150, top: 410, text: self.signature)
            self.newLabel(text: "User Handle", top: 570)
            self.userHandleText =
                self.newTextField(height: 30, top: 600, text: self.userHandle)
        }
        self.setupCloseButton()
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
    
    private func newTextView(height: CGFloat, top: CGFloat, text: String) -> UITextView {
        let view = ViewCatalog.createTextView()
        view.text = text
        view.fitScreenW(20)
        view.height(height)
        view.top(top)
        view.layer.cornerRadius = 5.0
        view.autocapitalizationType = .none
        view.backgroundColor = UIColor.white
        view.textColor = UIColor.black
        self.view.addSubview(view)
        view.centerizeScreenH()
        return view
    }
    
    private func setupCloseButton() {
        let button = ViewCatalog.createButton(text: "CLOSE")
        button.height(50)
        button.addTarget(self, action: #selector(type(of: self).onCloseButtonTapped(_:)), for: .touchUpInside)
        button.fitScreenW(20)
        button.centerizeScreenH()
        button.top(self.view.bounds.height - 50 - 50)
        
        button.layer.backgroundColor = UIColor.fromRGB(0xff4500).cgColor
        view.addSubview(button)
    }
    
    @objc func onCloseButtonTapped(_ sender: UIButton) {
       dismiss(animated: true, completion: nil)
    }
    
    private func resignAllTextViews() {
        [
            self.rawIdText,
            self.credIdText,
            self.clientDataJSONText,
            self.attestationObjectText,
            self.authenticatorDataText,
            self.signatureText,
            self.userHandleText
            ].forEach { textField in
                if let tv = textField {
                    if tv.isFirstResponder {
                        tv.resignFirstResponder()
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
