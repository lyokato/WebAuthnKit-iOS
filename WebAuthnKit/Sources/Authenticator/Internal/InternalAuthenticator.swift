//
//  InternalAuthenticator.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import PromiseKit
import CryptoSwift
import LocalAuthentication

public struct InternalAuthenticatorSetting {
    public let attachment: AuthenticatorAttachment = .platform
    public let transport: AuthenticatorTransport = .internal_
    public var counterStep: UInt32
    public var allowUserVerification: Bool
    
    public init(
        counterStep:           UInt32 = 1,
        allowUserVerification: Bool = true
    ) {
        self.counterStep           = counterStep
        self.allowUserVerification = allowUserVerification
    }
}

public class InternalAuthenticator : Authenticator {
    
    public var setting = InternalAuthenticatorSetting()
    
    public var attachment: AuthenticatorAttachment {
        get {
            return self.setting.attachment
        }
    }
    
    public var transport: AuthenticatorTransport {
        get {
            return self.setting.transport
        }
    }
    
    public var counterStep: UInt32 {
        get {
            return self.setting.counterStep
        }
        set(value) {
            self.setting.counterStep = value
        }
    }
    
    public var allowUserVerification: Bool {
        get {
            return self.setting.allowUserVerification
        }
        set(value) {
            self.setting.allowUserVerification = value
        }
    }
    
    public var allowResidentKey: Bool {
        get {
            return true
        }
    }

    private let ui:              UserConsentUI
    private let credentialStore: CredentialStore

    private let keySupportChooser = KeySupportChooser()
    
    public convenience init(ui: UserConsentUI) {
        let store = KeychainCredentialStore()
        self.init(
            ui:              ui,
            credentialStore: store
        )
    }

    public init(
        ui:              UserConsentUI,
        credentialStore: CredentialStore
    ) {
        self.ui              = ui
        self.credentialStore = credentialStore
    }

    public func newMakeCredentialSession(context: LAContext?) -> AuthenticatorMakeCredentialSession {
        WAKLogger.debug("<InternalAuthenticator> newMakeCredentialSession")
        return InternalAuthenticatorMakeCredentialSession(
            setting:           self.setting,
            ui:                self.ui,
            credentialStore:   self.credentialStore,
            keySupportChooser: self.keySupportChooser,
            context:           context
        )
    }
    
    public func newGetAssertionSession(context: LAContext?) -> AuthenticatorGetAssertionSession {
        WAKLogger.debug("<InternalAuthenticator> newGetAssertionSession")
        return InternalAuthenticatorGetAssertionSession(
            setting:           self.setting,
            ui:                self.ui,
            credentialStore:   self.credentialStore,
            keySupportChooser: self.keySupportChooser,
            context:           context
        )
    }

}
