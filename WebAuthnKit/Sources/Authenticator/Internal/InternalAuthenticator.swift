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

public struct InternalAuthenticatorSetting {
    public let attachment: AuthenticatorAttachment = .platform
    public let transport: AuthenticatorTransport = .internal_
    public var counterStep: UInt32
    public var allowResidentKey: Bool
    public var allowUserVerification: Bool
    
    public init(
        counterStep:           UInt32 = 1,
        allowResidentKey:      Bool = true,
        allowUserVerification: Bool = true
    ) {
        self.counterStep           = counterStep
        self.allowResidentKey      = allowResidentKey
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
    
    
    public var allowResidentKey: Bool {
        get {
            return self.setting.allowResidentKey
        }
        set(value) {
            self.setting.allowResidentKey = value
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

    private let ui:                  UserConsentUI
    private let credentialStore:     CredentialStore
    private let credentialEncryptor: CredentialEncryptor
    
    private let keySupportChooser = KeySupportChooser()
    
    public convenience init(
        ui:            UserConsentUI,
        encryptionKey: String
        ) {
        
        let key = encryptionKey.data(using: .utf8)!.bytes
        
        self.init(
            ui:                  ui,
            credentialEncryptor: AESGCMCredentialEncryptor(key: key),
            credentialStore:     KeychainCredentialStore()
        )
        
    }
    
    public convenience init(
        ui:            UserConsentUI,
        encryptionKey: [UInt8]
    ) {
       self.init(
            ui:                  ui,
            credentialEncryptor: AESGCMCredentialEncryptor(key: encryptionKey),
            credentialStore:     KeychainCredentialStore()
        )
    }
    
    public init(
        ui:                  UserConsentUI,
        credentialEncryptor: CredentialEncryptor,
        credentialStore:     CredentialStore
    ) {
        self.ui                  = ui
        self.credentialEncryptor = credentialEncryptor
        self.credentialStore     = credentialStore
    }

    public func newMakeCredentialSession() -> AuthenticatorMakeCredentialSession {
        return InternalAuthenticatorMakeCredentialSession(
            setting:             self.setting,
            ui:                  self.ui,
            credentialEncryptor: self.credentialEncryptor,
            credentialStore:     self.credentialStore,
            keySupportChooser:   self.keySupportChooser
        )
    }
    
    public func newGetAssertionSession() -> AuthenticatorGetAssertionSession {
        return InternalAuthenticatorGetAssertionSession(
            setting:             self.setting,
            ui:                  self.ui,
            credentialEncryptor: self.credentialEncryptor,
            credentialStore:     self.credentialStore,
            keySupportChooser:   self.keySupportChooser
        )
    }

}
