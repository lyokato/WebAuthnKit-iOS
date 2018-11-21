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

class ResultViewController: UIViewController {
    
    var rawId: String
    var hashedId: String
    var clientDataJSON: String
    var attestationObject: String
    
    init(
        rawId: String,
        hashedId: String,
        clientDataJSON: String,
        attestationObject: String
    ) {
        self.rawId = rawId
        self.hashedId = hashedId
        self.clientDataJSON = clientDataJSON
        self.attestationObject = attestationObject
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        self.view.addSubview(ViewCatalog.createBackground())
        self.navigationItem.title = "Result"
        
        
        //self.setupTextView()
        self.newLabel(text: "Raw Id (Hex)", top: 60)
        self.newTextView(height: 30, top: 90, text: self.rawId)
        self.newLabel(text: "Hashed Id", top: 130)
        self.newTextView(height: 30, top: 160, text: self.hashedId)
        self.newLabel(text: "Client Data JSON", top: 200)
        self.newTextView(height: 70, top: 230, text: self.clientDataJSON)
        self.newLabel(text: "Attestation Object (Base64URL)", top: 310)
        self.newTextView(height: 400, top: 340, text: self.attestationObject)
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
    
    private func newTextView(height: CGFloat, top: CGFloat, text: String) {
        let view = ViewCatalog.createTextView()
        view.text = text
        view.fitScreenW(20)
        view.height(height)
        view.top(top)
        view.autocapitalizationType = .none
        view.backgroundColor = UIColor.white
        view.textColor = UIColor.black
        self.view.addSubview(view)
        view.centerizeScreenH()
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
}
