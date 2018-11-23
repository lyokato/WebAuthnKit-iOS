//
//  ClientCreateOperation.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import PromiseKit

public class ClientCreateOperation: AuthenticatorMakeCredentialSessionDelegate {
    
    public let id = UUID().uuidString
    public let type = ClientOperationType.create
    
    public weak var delegate: ClientOperationDelegate?

    private let options:        PublicKeyCredentialCreationOptions
    private let rpId:           String
    private let clientData:     CollectedClientData
    private let clientDataJSON: String
    private let clientDataHash: [UInt8]
    private let lifetimeTimer:  UInt64
    
    private var session: AuthenticatorMakeCredentialSession

    private var resolver: Resolver<WebAuthnClient.CreateResponse>?
    private var stopped: Bool = false

    private var timer: Timer?

    internal init(
        options:        PublicKeyCredentialCreationOptions,
        rpId:           String,
        session:        AuthenticatorMakeCredentialSession,
        clientData:     CollectedClientData,
        clientDataJSON: String,
        clientDataHash: [UInt8],
        lifetimeTimer:  UInt64
    ) {
        self.options        = options
        self.rpId           = rpId
        self.session        = session
        self.clientData     = clientData
        self.clientDataJSON = clientDataJSON
        self.clientDataHash = clientDataHash
        self.lifetimeTimer  = lifetimeTimer
    }

    public func start() -> Promise<WebAuthnClient.CreateResponse> {
        WAKLogger.debug("<CreateOperation> start")
        return Promise { resolver in
            DispatchQueue.global().async {
                if self.stopped {
                    WAKLogger.debug("<CreateOperation> already stopped")
                    DispatchQueue.main.async {
                        resolver.reject(WAKError.badOperation)
                        self.delegate?.operationDidFinish(opType: self.type, opId: self.id)
                    }
                    return
                }
                if self.resolver != nil {
                    WAKLogger.debug("<CreateOperation> already started")
                    DispatchQueue.main.async {
                        resolver.reject(WAKError.badOperation)
                        self.delegate?.operationDidFinish(opType: self.type, opId: self.id)
                    }
                    return
                }
                self.resolver = resolver
                self.startLifetimeTimer()

                self.session.delegate = self
                self.session.start()
            }
        }
    }

    public func cancel() {
        WAKLogger.debug("<CreateOperation> cancel")
        DispatchQueue.global().async {
            self.stop(by: .cancelled)
        }
    }

    private func stop() {
        WAKLogger.debug("<CreateOperation> stop")
        if self.resolver == nil {
            WAKLogger.debug("<CreateOperation> not started")
            return
        }
        if self.stopped {
            WAKLogger.debug("<CreateOperation> already stopped")
            return
        }
        self.stopped = true
        self.stopLifetimeTimer()
        self.session.cancel()
        self.delegate?.operationDidFinish(opType: self.type, opId: self.id)
    }

    // MARK: Private Methods

    private func stop(by error: WAKError) {
        WAKLogger.debug("<CreateOperation> stop by \(error)")
        self.stop()
        self.dispatchError(error)
    }

    private func dispatchError(_ error: WAKError) {
        WAKLogger.debug("<CreateOperation> dispatchError")
        DispatchQueue.main.async {
            if let resolver = self.resolver {
                resolver.reject(error)
                self.resolver = nil
            }
        }
    }

    private func startLifetimeTimer() {
        WAKLogger.debug("<CreateOperation> startLifetimeTimer: \(self.lifetimeTimer) sec")
        if self.timer != nil {
            WAKLogger.debug("<CreateOperation> timer already started")
            return
        }
        self.timer = Timer.scheduledTimer(
            timeInterval: TimeInterval(self.lifetimeTimer),
            target:       self,
            selector:     #selector(ClientCreateOperation.lifetimeTimerTimeout),
            userInfo:     nil,
            repeats:      false
        )
    }

    private func stopLifetimeTimer() {
        WAKLogger.debug("<CreateOperation> stopLifetimeTimer")
        self.timer?.invalidate()
        self.timer = nil
    }

    @objc func lifetimeTimerTimeout() {
        WAKLogger.debug("<CreateOperation> timeout")
        self.stop(by: .timeout)
    }

    private func judgeUserVerificationExecution(_ session: AuthenticatorMakeCredentialSession) -> Bool {
        WAKLogger.debug("<CreateOperation> judgeUserVerificationExecution")
        let userVerificationRequest =
            self.options.authenticatorSelection?.userVerification ?? .discouraged
        switch userVerificationRequest {
        case .required:
            return true
        case .preferred:
            return session.canPerformUserVerification()
        case .discouraged:
            return false
        }
    }

    // MARK: AuthenticatorMakeCredentialSessionDelegate Methods

    /// 5.1.3 - 20
    public func authenticatorSessionDidBecomeAvailable(session: AuthenticatorMakeCredentialSession) {
        
        WAKLogger.debug("<CreateOperation> authenticator become available")

        if self.stopped {
            WAKLogger.debug("<CreateOperation> already stopped")
            return
        }

        if let selection = self.options.authenticatorSelection {

            // XXX should be checked beforehand?
            if let attachment = selection.authenticatorAttachment {
                if attachment != session.attachment {
                    WAKLogger.debug("<CreateOperation> authenticator's attachment doesn't match to RP's request")
                    self.stop(by: .unsupported)
                    return
                }
            }

            if selection.requireResidentKey
                && !session.canStoreResidentKey() {
                WAKLogger.debug("<CreateOperation> This authenticator can't store resident-key")
                self.stop(by: .unsupported)
                return
            }

            if selection.userVerification == .required
                && !session.canPerformUserVerification() {
                WAKLogger.debug("<CreateOperation> This authenticator can't perform user verification")
                self.stop(by: .unsupported)
                return
            }

            let userVerification =
                self.judgeUserVerificationExecution(session)

            let userPresence = !userVerification

            let excludeCredentialDescriptorList =
                self.options.excludeCredentials.filter {descriptor in
                    if descriptor.transports.contains(session.transport) {
                        return false
                    } else {
                        return true
                    }
            }

            let requireResidentKey =
                options.authenticatorSelection?.requireResidentKey ?? false

            let rpEntity = PublicKeyCredentialRpEntity(
                id:   self.rpId,
                name: options.rp.name,
                icon: options.rp.icon
            )

            session.makeCredential(
                hash:                            self.clientDataHash,
                rpEntity:                        rpEntity,
                userEntity:                      options.user,
                requireResidentKey:              requireResidentKey,
                requireUserPresence:             userPresence,
                requireUserVerification:         userVerification,
                credTypesAndPubKeyAlgs:          options.pubKeyCredParams,
                excludeCredentialDescriptorList: excludeCredentialDescriptorList
            )
        }
    }

    public func authenticatorSessionDidBecomeUnavailable(session: AuthenticatorMakeCredentialSession) {
        WAKLogger.debug("<CreateOperation> authenticator become unavailable")
        self.stop(by: .notAllowed)
    }

    public func authenticatorSessionDidMakeCredential(
        session:     AuthenticatorMakeCredentialSession,
        attestation: AttestationObject
    ) {
        WAKLogger.debug("<CreateOperation> authenticator made credential")
        
        guard let attestedCred =
            attestation.authData.attestedCredentialData else {
            WAKLogger.debug("<CreateOperation> attested credential data not found")
            self.dispatchError(.unknown)
            return
        }

        let credentialId = attestedCred.credentialId

        var atts = attestation
        
        // XXX currently not support replacing attestation
        //     on "indirect" conveyance request
        
        var attestationObject: [UInt8]! = nil
        if self.options.attestation == .none && !attestation.isSelfAttestation() {
            WAKLogger.debug("<CreateOperation> attestation conveyance request is 'none', but this is not a self-attestation.")
            atts = attestation.toNone()
            guard let bytes = atts.toBytes() else {
                WAKLogger.debug("<CreateOperation> failed to build attestation-object")
                self.dispatchError(.unknown)
                return
            }
            attestationObject = bytes
            
            WAKLogger.debug("<CreateOperation> replace AAGUID with zero")
            let guidPos = 37 // ( rpIdHash(32), flag(1), signCount(4) )
            (guidPos..<(guidPos+16)).forEach { attestationObject[$0] = 0x00 }
        } else {
            guard let bytes = atts.toBytes() else {
                WAKLogger.debug("<CreateOperation> failed to build attestation-object")
                self.dispatchError(.unknown)
                return
            }
            attestationObject = bytes
        }

        let response =
            AuthenticatorAttestationResponse(
                clientDataJSON:    self.clientDataJSON,
                attestationObject: attestationObject
            )

        // TODO support extensionResult
        let cred = PublicKeyCredential<AuthenticatorAttestationResponse>(
            rawId:    credentialId,
            id:       Base64.encodeBase64URL(credentialId),
            response: response
        )

        self.stop()
        
        DispatchQueue.main.async {
            if let resolver = self.resolver {
                resolver.fulfill(cred)
                self.resolver = nil
            }
        }
    }

    public func authenticatorSessionDidStopOperation(
        session: AuthenticatorMakeCredentialSession,
        reason:  AuthenticatorError
    ) {
        WAKLogger.debug("<CreateOperation> authenticator stopped operation")
        switch reason {
        case .invalidStateError:
            self.stop(by: .invalidState)
        case .userCancelled:
            self.stop(by: .cancelled)
        default:
            self.stop(by: .notAllowed)
        }
    }
}
