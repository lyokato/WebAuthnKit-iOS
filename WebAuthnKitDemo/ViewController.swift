//
//  ViewController.swift
//  WebAuthnKitDemo
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        self.view.addSubview(ViewCatalog.createBackground())
        self.navigationItem.title = "Choose Mode"
        
        self.setupTitleLabel()
        self.setupRegistrationButton()
        self.setupAuthenticationButton()
    }
    
    private func setupRegistrationButton() {
       let button = ViewCatalog.createButton(text: "REGISTRATION")
        button.height(50)
        button.addTarget(self, action: #selector(type(of: self).onRegistrationButtonTapped(_:)), for: .touchUpInside)
        button.fitScreenW(20)
        button.centerizeScreenH()
        button.top(170)
        
        button.layer.backgroundColor = UIColor.fromRGB(0xff4500).cgColor
        view.addSubview(button)
    }
    
    private func setupAuthenticationButton() {
        let button = ViewCatalog.createButton(text: "AUTHENTICATION")
        button.height(50)
        button.addTarget(self, action: #selector(type(of: self).onAuthenticationButtonTapped(_:)), for: .touchUpInside)
        button.fitScreenW(20)
        button.centerizeScreenH()
        button.top(250)
        
        button.layer.backgroundColor = UIColor.fromRGB(0xff4500).cgColor
        view.addSubview(button)
    }
    
    @objc func onRegistrationButtonTapped(_ sender: UIButton) {
        let vc = RegistrationViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func onAuthenticationButtonTapped(_ sender: UIButton) {
        let vc = AuthenticationViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setupTitleLabel() {
        let label = ViewCatalog.createLabel(text: "WebAuthenDemo")
        label.height(30)
        label.fitScreenW(10)
        label.centerizeScreenH()
        label.top(120)
        label.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        label.textColor = UIColor.white
        view.addSubview(label)
    }


}

