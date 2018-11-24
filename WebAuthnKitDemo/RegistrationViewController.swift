//
//  RegistrationViewController.swift
//  WebAuthnKitDemo
//
//  Created by Lyo Kato on 2018/11/21.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import UIKit
import WebAuthnKit
import PromiseKit
import CryptoSwift

public enum FormError : Error {
    case missing(String)
    case empty(String)
}

class RegistrationViewController: UIViewController, UITextFieldDelegate {
    
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
        
        let authenticator = InternalAuthenticator(ui: self.userConsentUI)
        
        self.webAuthnClient = WebAuthnClient(
            origin:        "https://example.org",
            authenticator: authenticator
        )
    }
    
    private func startRegistration() {
        
        guard let challenge = self.challengeText.text else {
            self.showErrorPopup(FormError.missing("challenge"))
            return
        }
        if challenge.isEmpty {
            self.showErrorPopup(FormError.empty("challenge"))
            return
        }
        
        guard let userId = self.userIdText.text else {
            self.showErrorPopup(FormError.missing("userId"))
            return
        }
        if userId.isEmpty {
            self.showErrorPopup(FormError.empty("userId"))
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
        
        let attestation = [
            AttestationConveyancePreference.direct,
            AttestationConveyancePreference.indirect,
            AttestationConveyancePreference.none,
        ][self.attestationConveyance.selectedSegmentIndex]
        
        let verification = [
            UserVerificationRequirement.required,
            UserVerificationRequirement.preferred,
            UserVerificationRequirement.discouraged
        ][self.userVerification.selectedSegmentIndex]
        
        let requireResidentKey = [true, false][self.residentKeyRequired.selectedSegmentIndex]
        
        var options = PublicKeyCredentialCreationOptions()
        options.challenge = Bytes.fromHex(challenge)
        options.user.id = Bytes.fromString(userId)
        
        if let displayName = self.displayNameText.text {
            if !displayName.isEmpty {
                options.user.name        = displayName
                options.user.displayName = displayName
            }
        }
        
        if let iconURL = self.userIconURLText.text {
            if !iconURL.isEmpty {
                options.user.icon = iconURL
            }
        }
        
        options.rp.id = rpId
        options.rp.name = rpId
        
        if let iconURL = self.rpIconURLText.text {
            if !iconURL.isEmpty {
                options.rp.icon = iconURL
            }
        }
        
        options.attestation = attestation
        options.addPubKeyCredParam(alg: .es256)
        options.authenticatorSelection = AuthenticatorSelectionCriteria(
            requireResidentKey: requireResidentKey,
            userVerification: verification
        )
        // options.timeout = UInt64(120)

        firstly {
            
            self.webAuthnClient.create(options)
            
        }.done { credential in

            self.showResult(credential)

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
    
    var userIdText:            UITextField!
    var displayNameText:       UITextField!
    var userIconURLText:       UITextField!
    var rpIconURLText:         UITextField!
    var rpIdText:              UITextField!
    var challengeText:         UITextField!
    var userVerification:      UISegmentedControl!
    var attestationConveyance: UISegmentedControl!
    var residentKeyRequired:   UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        WAKLogger.available = true
        
        view.backgroundColor = UIColor.black
        self.view.addSubview(ViewCatalog.createBackground())
        self.navigationItem.title = "Registration"
        
        var offset: CGFloat = 100
        
        self.newLabel(text: "User Id", top: offset)
        self.userIdText = self.newTextField(height: 30, top: offset + 30, text: "lyokato")
        
        offset = offset + 70
        
        self.newLabel(text: "User Display Name", top: offset)
        self.displayNameText = self.newTextField(height: 30, top: offset + 30, text: "Lyo Kato")
        
        offset = offset + 70
        
        self.newLabel(text: "User ICON URL (Optional)", top: offset)
        self.userIconURLText = self.newTextField(height: 30, top: offset + 30, text: "https://www.gravatar.com/avatar/0b63462eb18efbfb764b0c226abff4a0?s=440&d=retro")

        offset = offset + 70
        
        self.newLabel(text: "Relying Party Id", top: offset)
        self.rpIdText = self.newTextField(height: 30, top: offset + 30, text: "https://example.org")
        
        offset = offset + 70
        
        self.newLabel(text: "Relying Party Icon", top: offset)
        self.rpIconURLText = self.newTextField(height: 30, top: offset + 30, text: "https://developers.google.com/identity/images/g-logo.png")
        
        offset = offset + 70
        
        self.newLabel(text: "Challenge (Hex)", top: offset)
        self.challengeText = self.newTextField(height: 30, top: offset + 30, text: "aed9c789543b")
        
        offset = offset + 80
        
        self.newLabel(text: "User Verification", top: offset)
        self.userVerification = self.newSegmentedControl(top: offset + 30, list: ["Required", "Preferred", "Discouraged"])
        
        offset = offset + 80
        
        self.newLabel(text: "Attestation Conveyance", top: offset)
        self.attestationConveyance = self.newSegmentedControl(top: offset + 30, list: ["Direct", "Indirect", "None"])
        
        offset = offset + 80

        self.newLabel(text: "Resident Key Required", top: offset)
        self.residentKeyRequired = self.newSegmentedControl(top: offset + 30, list: ["Required", "Not Required"])

        self.setupWebAuthnClient()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Start", style: .plain, target: self, action: #selector(RegistrationViewController.onStartButtonTapped))
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
        self.view.addSubview(view)
        view.centerizeScreenH()
        view.font = UIFont.systemFont(ofSize: 12)
        return view
    }

    @objc func onStartButtonTapped() {
        self.startRegistration()
    }
    
    private func showResult(_ credential: WebAuthnClient.CreateResponse) {
        
        let rawId             = credential.rawId.toHexString()
        let credId            = credential.id
        let clientDataJSON    = credential.response.clientDataJSON
        let attestationObject = Base64.encodeBase64URL(credential.response.attestationObject)

        let vc = ResultViewController(
            rawId:             rawId,
            credId:            credId,
            clientDataJSON:    clientDataJSON,
            attestationObject: attestationObject
        )
        
        self.present(vc, animated: true, completion: nil)
    }
    
    private func resignAllTextViews() {
        [
            userIdText,
            displayNameText,
            userIconURLText,
            rpIconURLText,
            rpIdText,
            challengeText
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

