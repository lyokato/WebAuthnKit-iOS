//
//  InternalAuthenticatorMakeCredentialSession.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import PromiseKit
import CryptoSwift

public class InternalAuthenticatorMakeCredentialSession : AuthenticatorMakeCredentialSession {
    
    public weak var delegate: AuthenticatorMakeCredentialSessionDelegate?
    
    private let setting: InternalAuthenticatorSetting
    
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
    
    private let ui:                  UserConsentUI
    private let credentialStore:     CredentialStore
    private let credentialEncryptor: CredentialEncryptor
    private let keySupportChooser:   KeySupportChooser
    
    private var started = false
    private var stopped = false
    
    init(
        setting:             InternalAuthenticatorSetting,
        ui:                  UserConsentUI,
        credentialEncryptor: CredentialEncryptor,
        credentialStore:     CredentialStore,
        keySupportChooser:   KeySupportChooser
    ) {
        self.setting             = setting
        self.ui                  = ui
        self.credentialEncryptor = credentialEncryptor
        self.credentialStore     = credentialStore
        self.keySupportChooser   = keySupportChooser
    }
    
    public func canPerformUserVerification() -> Bool {
        return self.setting.allowUserVerification
    }
    
    public func canStoreResidentKey() -> Bool {
        return self.setting.allowResidentKey
    }
    
    public func start() {
        if self.stopped {
            return
        }
        if self.started {
            return
        }
        self.started = true
        self.delegate?.authenticatorSessionDidBecomeAvailable(session: self)
    }
    
    // 6.3.4 authenticatorCancel Operation
    public func cancel() {
        self.stop(by: .userCancelled)
    }
    
    private func stop(by reason: AuthenticatorError) {
        if !self.started {
            return
        }
        if self.stopped  {
            return
        }
        self.stopped = true
        self.delegate?.authenticatorSessionDidStopOperation(
            session: self,
            reason:  reason
        )
    }
    
    private func completed() {
        self.stopped = true
    }
    
    private func createNewCredentialId() -> [UInt8] {
        return UUIDHelper.toBytes(UUID())
    }
    
    // 6.3.2 authenticatorMakeCredential Operation
    public func makeCredential(
        hash:                            [UInt8],// hash of ClientData
        rpEntity:                        PublicKeyCredentialRpEntity,
        userEntity:                      PublicKeyCredentialUserEntity,
        requireResidentKey:              Bool,
        requireUserPresence:             Bool,
        requireUserVerification:         Bool,
        credTypesAndPubKeyAlgs:          [PublicKeyCredentialParameters] = [PublicKeyCredentialParameters](),
        excludeCredentialDescriptorList: [PublicKeyCredentialDescriptor] = [PublicKeyCredentialDescriptor]()) {
        
        WAKLogger.debug("<MakeCredentialSession> make credential")
        
        let requestedAlgs = credTypesAndPubKeyAlgs.map { $0.alg }
        
        guard let keySupport =
            self.keySupportChooser.choose(requestedAlgs) else {
                WAKLogger.debug("<MakeCredentialSession> insufficient capability (alg), stop session")
                self.stop(by: .notSupportedError)
                return
        }
        
        let hasSourceToBeExcluded = excludeCredentialDescriptorList.contains {
            self.lookupCredentialSource(rpId: rpEntity.id!, credentialId: $0.id) != nil
        }
        
        if hasSourceToBeExcluded {
            firstly {
                self.ui.askUserToCreateNewCredential(rpId: rpEntity.id!)
                }.done {
                    self.stop(by: .invalidStateError)
                    return
                }.catch { error in
                    switch error {
                    case AuthenticatorError.notAllowedError:
                        self.stop(by: .notAllowedError)
                        return
                    default:
                        self.stop(by: .unknownError)
                        return
                    }
            }
            return
        }
        
        if requireResidentKey && !self.setting.allowResidentKey {
            WAKLogger.debug("<MakeCredentialSession> insufficient capability (resident key), stop session")
            self.stop(by: .constraintError)
            return
        }
        
        if requireUserVerification && !self.setting.allowUserVerification {
            WAKLogger.debug("<MakeCredentialSession> insufficient capability (user verification), stop session")
            self.stop(by: .constraintError)
            return
        }
        
        firstly {
            
            self.ui.requestUserConsent(
                rpEntity:            rpEntity,
                userEntity:          userEntity,
                requireVerification: requireUserVerification
            )
            
            }.done { keyName in
                
                var credSource = PublicKeyCredentialSource(
                    rpId:       rpEntity.id!,
                    userHandle: userEntity.id,
                    alg:        keySupport.selectedAlg.rawValue
                )
                
                credSource.otherUI = keyName
                
                // got user consent
                guard let publicKeyCOSE = keySupport.createKeyPair(label: credSource.keyLabel) else {
                    self.stop(by: .unknownError)
                    return
                }
                
                var credentialId = [UInt8]()
                var signCount: UInt32 = 0
                
                self.credentialStore.deleteAllCredentialSources(
                    rpId:       credSource.rpId,
                    userHandle: credSource.userHandle
                )
                
                if requireResidentKey && self.setting.allowResidentKey {
                    
                    WAKLogger.debug("<MakeCredentialSession> setup key as resident-key")
                    
                    credentialId = self.createNewCredentialId()
                    credSource.id = credentialId
                    credSource.isResidentKey = true
                    
                    if !self.credentialStore.saveCredentialSource(credSource) {
                        WAKLogger.debug("<MakeCredentialSession> failed to save credential source, stop session")
                        self.stop(by: .unknownError)
                        return
                    }
                    
                } else {
                    
                    WAKLogger.debug("<MakeCredentialSession> setup key as encrypted-key")
                    
                    if let encrypted =
                        self.credentialEncryptor.encryptCredentialSource(credSource) {
                        credentialId = encrypted
                    } else {
                        WAKLogger.debug("<MakeCredentialSession> failed to encrypt credential source, stop session")
                        self.stop(by: .unknownError)
                        return
                    }
                    
                    guard let count = self.credentialStore.loadGlobalSignCounter(rpId: rpEntity.id!) else {
                        WAKLogger.debug("<MakeCredentialSession> failed to load global count")
                        self.stop(by: .unknownError)
                        return
                    }
                    
                    signCount = count + self.setting.counterStep
                    
                    if !self.credentialStore.saveGlobalSignCounter(rpId: rpEntity.id!, count: signCount) {
                        WAKLogger.debug("<MakeCredentialSession> failed to save global count")
                        self.stop(by: .unknownError)
                        return
                    }
                    
                }
                
                // TODO Extension Processing
                let extensions = SimpleOrderedDictionary<String>()
                
                let attestedCredData = AttestedCredentialData(
                    aaguid:              UUIDHelper.zeroBytes,
                    credentialId:        credentialId,
                    credentialPublicKey: publicKeyCOSE
                )
                
                let authenticatorData = AuthenticatorData(
                    rpIdHash:               rpEntity.id!.bytes.sha256(),
                    userPresent:            requireUserPresence,
                    userVerified:           requireUserVerification,
                    signCount:              signCount,
                    attestedCredentialData: attestedCredData,
                    extensions:             extensions
                )
                
                guard let attestation =
                    SelfAttestation.create(
                        authData:       authenticatorData,
                        clientDataHash: hash,
                        alg:            keySupport.selectedAlg,
                        keyLabel:       credSource.keyLabel
                    ) else {
                        WAKLogger.debug("<MakeCredentialSession> failed to build attestation object")
                        self.stop(by: .unknownError)
                        return
                }
                
                self.completed()
                self.delegate?.authenticatorSessionDidMakeCredential(
                    session:     self,
                    attestation: attestation
                )
                
            }.catch { error in
                // When failed to got user consent
                switch error {
                case AuthenticatorError.notAllowedError:
                    self.stop(by: .notAllowedError)
                    return
                default:
                    self.stop(by: .unknownError)
                    return
                }
        }
    }
    
    // 6.3.1 Lookup Credential Source By Credential ID Algoreithm
    private func lookupCredentialSource(rpId: String, credentialId: [UInt8])
        -> Optional<PublicKeyCredentialSource> {
            WAKLogger.debug("<MakeCredentialSession> lookupCredentialSource")
            if let src = self.credentialStore.lookupCredentialSource(
                rpId:         rpId,
                credentialId: credentialId) {
                return src
            } else {
                guard var src = self.credentialEncryptor.decryptCredentialId(credentialId) else {
                    return nil
                }
                src.id = credentialId
                src.isResidentKey = false
                return src
            }
    }
    
}
