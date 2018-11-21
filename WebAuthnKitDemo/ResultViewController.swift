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
    
    var result: String
    
    init(result: String) {
        self.result = result
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
        
        self.setupTextView()
        self.setupCloseButton()
    }
    
    private func setupTextView() {
        let view = ViewCatalog.createTextView()
        view.text = self.result
        view.fitScreenW(20)
        view.height(self.view.bounds.height - 50 - 50 - 50 - 20)
        view.top(50)
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
