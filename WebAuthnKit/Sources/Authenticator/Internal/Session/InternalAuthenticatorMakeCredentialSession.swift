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
    
    private let ui:                UserConsentUI
    private let credentialStore:   CredentialStore
    private let keySupportChooser: KeySupportChooser
    
    private var started = false
    private var stopped = false
    
    init(
        setting:           InternalAuthenticatorSetting,
        ui:                UserConsentUI,
        credentialStore:   CredentialStore,
        keySupportChooser: KeySupportChooser
    ) {
        self.setting           = setting
        self.ui                = ui
        self.credentialStore   = credentialStore
        self.keySupportChooser = keySupportChooser
    }
    
    public func canPerformUserVerification() -> Bool {
        return self.setting.allowUserVerification
    }
    
    public func canStoreResidentKey() -> Bool {
        return true
    }
    
    public func start() {
        if self.stopped {
            WAKLogger.debug("<MakeCredentialSession> already stopped")
            return
        }
        if self.started {
            WAKLogger.debug("<MakeCredentialSession> already started")
            return
        }
        self.started = true
        self.delegate?.authenticatorSessionDidBecomeAvailable(session: self)
    }
    
    // 6.3.4 authenticatorCancel Operation
    public func cancel(reason: WAKError) {
        WAKLogger.debug("<MakeCredentialSession> cancel")
        if self.stopped {
            WAKLogger.debug("<MakeCredentialSession> already stopped")
            return
        }
        if self.ui.opened {
            WAKLogger.debug("<MakeCredentialSession> during user interaction")
            self.ui.cancel(reason: reason)
        } else {
            self.stop(by: reason)
        }
    }
    
    private func stop(by reason: WAKError) {
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
                self.stop(by: .unsupported)
                return
        }
        
        let hasSourceToBeExcluded = excludeCredentialDescriptorList.contains {
            self.credentialStore.lookupCredentialSource(
                rpId:         rpEntity.id!,
                credentialId: $0.id
            ) != nil
        }
        
        if hasSourceToBeExcluded {
            firstly {
                self.ui.askUserToCreateNewCredential(rpId: rpEntity.id!)
                }.done {
                    self.stop(by: .invalidState)
                    return
                }.catch { error in
                    switch error {
                    case WAKError.notAllowed:
                        self.stop(by: .notAllowed)
                        return
                    default:
                        self.stop(by: .unknown)
                        return
                    }
            }
            return
        }
        
        if requireUserVerification && !self.setting.allowUserVerification {
            WAKLogger.debug("<MakeCredentialSession> insufficient capability (user verification), stop session")
            self.stop(by: .constraint)
            return
        }
        
        firstly {
            
            self.ui.requestUserConsent(
                rpEntity:            rpEntity,
                userEntity:          userEntity,
                requireVerification: requireUserVerification
            )
            
        }.done { keyName in
                
            let credentialId = self.createNewCredentialId()

            let credSource = PublicKeyCredentialSource(
                id:         credentialId,
                rpId:       rpEntity.id!,
                userHandle: userEntity.id,
                signCount:  0,
                alg:        keySupport.selectedAlg.rawValue,
                otherUI:    keyName
            )

            self.credentialStore.deleteAllCredentialSources(
                rpId:       credSource.rpId,
                userHandle: credSource.userHandle
            )

            // TODO should remove fron KeyPair too?

            guard let publicKeyCOSE = keySupport.createKeyPair(label: credSource.keyLabel) else {
                self.stop(by: .unknown)
                return
            }

            WAKLogger.debug("<MakeCredentialSession> setup key as resident-key")

            if !self.credentialStore.saveCredentialSource(credSource) {
                WAKLogger.debug("<MakeCredentialSession> failed to save credential source, stop session")
                self.stop(by: .unknown)
                return
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
                signCount:              0,
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
                    self.stop(by: .unknown)
                    return
            }

            self.completed()
            self.delegate?.authenticatorSessionDidMakeCredential(
                session:     self,
                attestation: attestation
            )

        }.catch { error in
            if let err = error as? WAKError {
                self.stop(by: err)
            } else {
                self.stop(by: .unknown)
            }
        }
    }
    
    // 6.3.1 Lookup Credential Source By Credential ID Algoreithm
    private func lookupCredentialSource(rpId: String, credentialId: [UInt8])
        -> Optional<PublicKeyCredentialSource> {
            WAKLogger.debug("<MakeCredentialSession> lookupCredentialSource")
            return self.credentialStore.lookupCredentialSource(
                rpId:         rpId,
                credentialId: credentialId
            )
    }
    
}
