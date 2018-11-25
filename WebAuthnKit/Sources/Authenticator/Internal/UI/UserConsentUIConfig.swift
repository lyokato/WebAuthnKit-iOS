//
//  UserConsentUIConfig.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/25.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation

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

    public init() {}

}
