//
//  UserConsentUIConfig.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/25.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import LocalAuthentication

public class UserConsentUIConfig {
    
    public var excludeKeyFoundPopupTitle: String = "Key Already Exists"
    public var excludeKeyFoundPopupMessage: String = "Force to create new key?"
    public var excludeKeyFoundPopupCancelButtonText: String = "Cancel"
    public var excludeKeyFoundPopupCreateButtonText: String = "Create"

    public var keyCreationTitle: String = "New Login Key"
    public var keyCreationCancelButtonText: String = "Cancel"
    public var keyCreationCreateButtonText: String = "Create"

    public var keySelectionTitle: String = "Choose Account"
    public var keySelectionCancelButtonText: String = "Cancel"
    public var keySelectionSelectButtonText: String = "Select"
    
    public var showRPInformation: Bool = true
    public var alwaysShowKeySelection: Bool = false
    public var requireBiometrics: Bool = false
    
    public var borderLightColor: UInt = 0xbbbbbb
    public var titleTextLightColor: UIColor = UIColor.black
    public var fieldTextLightColor: UIColor = UIColor.white
    public var pickerBackgroundLightColor: UIColor = UIColor.lightGray.withAlphaComponent(0.2)
    public var viewBorderLightColor: UInt = 0xdddddd
    
    public var borderDarkColor: UInt = 0x444444
    public var titleTextDarkColor: UIColor = UIColor.white
    public var fieldTextDarkColor: UIColor = UIColor.black
    public var pickerBackgroundDarkColor: UIColor = UIColor.darkGray.withAlphaComponent(0.2)
    public var viewBorderDarkColor: UInt = 0x222222

    public init() {}
    
    public var localAuthPolicy: LAPolicy {
        get {
            return self.requireBiometrics ?
                .deviceOwnerAuthenticationWithBiometrics :
                .deviceOwnerAuthentication
        }
    }
    
    public var titleTextColor: UIColor {
        get {
            if #available(iOS 13.0, *) {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    return titleTextDarkColor;
                }
            }
            return titleTextLightColor;
        }
    }
    
    public var pickerBackgroundColor: UIColor {
        get {
            if #available(iOS 13.0, *) {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    return pickerBackgroundDarkColor;
                }
            }
            return pickerBackgroundLightColor;
        }
    }
    
    public var fieldTextColor: UIColor {
        get {
            if #available(iOS 13.0, *) {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    return fieldTextDarkColor;
                }
            }
            return fieldTextLightColor;
        }
    }
    
    public var borderColor: UInt {
        get {
            if #available(iOS 13.0, *) {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    return borderDarkColor;
                }
            }
            return borderLightColor;
        }
    }
    
    public var viewBorderColor: UInt {
        get {
            if #available(iOS 13.0, *) {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    return viewBorderDarkColor;
                }
            }
            return viewBorderLightColor;
        }
    }

}
