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
        
        self.setupCloseButton()
    }
    
    private func setupTextView() {
        
    }
    
    private func setupCloseButton() {
        let button = ViewCatalog.createButton(text: "CLOSE")
        button.height(50)
        button.addTarget(self, action: #selector(type(of: self).onCloseButtonTapped(_:)), for: .touchUpInside)
        button.fitScreenW(20)
        button.centerizeScreenH()
        button.top(100)
        
        button.layer.backgroundColor = UIColor.fromRGB(0xff4500).cgColor
        view.addSubview(button)
    }
    
    @objc func onCloseButtonTapped(_ sender: UIButton) {
       dismiss(animated: true, completion: nil)
    }
}
