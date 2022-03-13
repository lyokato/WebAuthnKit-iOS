//
//  Client.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import PromiseKit
import CryptoSwift
import LocalAuthentication

public enum ClientOperationType {
   case get
   case create
}

public protocol ClientOperationDelegate: class {
    func operationDidFinish(opType: ClientOperationType, opId: String)
}

public class WebAuthnClient: ClientOperationDelegate {

    public typealias CreateResponse = PublicKeyCredential<AuthenticatorAttestationResponse>
    public typealias GetResponse = PublicKeyCredential<AuthenticatorAssertionResponse>

    public let origin: String

    public var defaultTimeout: UInt64 = 60
    public var minTimeout: UInt64 = 15
    public var maxTimeout: UInt64 = 120

    private let authenticator: Authenticator

    private var getOperations = [String: ClientGetOperation]()
    private var createOperations = [String: ClientCreateOperation]()

    public init(
        origin:        String,
        authenticator: Authenticator
    ) {
        self.origin        = origin
        self.authenticator = authenticator
    }

    public func create(_ options: PublicKeyCredentialCreationOptions, context: LAContext? = nil)
        -> Promise<CreateResponse> {

            WAKLogger.debug("<WebAuthnClient> create")

            return Promise { resolver in

                let op = self.newCreateOperation(options, context: context)
                op.delegate = self
                self.createOperations[op.id] = op

                let promise = op.start()
                promise.done {cred in

                    resolver.fulfill(cred)

                }.catch { error in

                    resolver.reject(error)

                }
            }
    }

    public func get(_ options: PublicKeyCredentialRequestOptions, context: LAContext? = nil)
        -> Promise<GetResponse> {

            WAKLogger.debug("<WebAuthnClient> get")

            return Promise { resolver in
                
                let op = self.newGetOperation(options, context: context)
                op.delegate = self
                self.getOperations[op.id] = op

                let promise = op.start()
                promise.done {cred in

                    resolver.fulfill(cred)

                }.catch { error in

                    resolver.reject(error)

                }

            }
    }

    public func cancel() {
        WAKLogger.debug("<WebAuthnClient> cancel")
        self.getOperations.forEach { $0.value.cancel() }
        self.createOperations.forEach { $0.value.cancel() }
    }

    /// this function comforms to https://www.w3.org/TR/webauthn/#createCredential
    public func newCreateOperation(_ options: PublicKeyCredentialCreationOptions, context: LAContext?)
        -> ClientCreateOperation {

            WAKLogger.debug("<WebAuthnClient> newCreateOperation")

            let lifetimeTimer = self.adjustLifetimeTimer(options.timeout)
            let rpId = self.pickRelyingPartyID(options.rp.id)

            // 5.1.3 - 9,10
            // check options.pubKeyCredParmas
            // currently 'public-key' is only in specification.
            // do nothing

            // TODO Extension handling
            // 5.1.3 - 11
            // 5.1.3 - 12

            // 5.1.3 - 13,14,15 Prepare ClientData, JSON, Hash
            let (clientData, clientDataJSON, clientDataHash) =
                self.generateClientData(
                    type:      .webAuthnCreate,
                    challenge: Base64.encodeBase64URL(options.challenge)
                )

            let session = self.authenticator.newMakeCredentialSession(context: context)

            return ClientCreateOperation(
                options:        options,
                rpId:           rpId,
                session:        session,
                clientData:     clientData,
                clientDataJSON: clientDataJSON,
                clientDataHash: clientDataHash,
                lifetimeTimer:  lifetimeTimer
            )

    }

    public func newGetOperation(_ options: PublicKeyCredentialRequestOptions, context: LAContext?)
        -> ClientGetOperation {

        WAKLogger.debug("<WebAuthnClient> newGetOperation")

        let lifetimeTimer = self.adjustLifetimeTimer(options.timeout)
        let rpId = self.pickRelyingPartyID(options.rpId)

        // TODO Extension handling
        // 5.1.4 - 8,9

        // 5.1.4 - 10, 11, 12
        let (clientData, clientDataJSON, clientDataHash) =
            self.generateClientData(
                type:      .webAuthnGet,
                challenge: Base64.encodeBase64URL(options.challenge)
        )

        let session = self.authenticator.newGetAssertionSession(context: context)

        return ClientGetOperation(
            options:        options,
            rpId:           rpId,
            session:        session,
            clientData:     clientData,
            clientDataJSON: clientDataJSON,
            clientDataHash: clientDataHash,
            lifetimeTimer:  lifetimeTimer
        )
    }

    public func operationDidFinish(opType: ClientOperationType, opId: String) {
        WAKLogger.debug("<WebAuthnClient> operationDidFinish")
        switch opType {
        case .get:
            self.getOperations.removeValue(forKey: opId)
        case .create:
            self.createOperations.removeValue(forKey: opId)
        }
    }

    /// this function comforms to https://www.w3.org/TR/webauthn/#createCredential
    /// 5.1.3 - 4
    /// If the timeout member of options is present, check if its value lies within a reasonable
    /// range as defined by the client and if not, correct it to the closest value lying within that range.
    /// Set a timer lifetimeTimer to this adjusted value. If the timeout member of options is not present,
    /// then set lifetimeTimer to a client-specific default.
    private func adjustLifetimeTimer(_ timeout: UInt64?) -> UInt64 {
        WAKLogger.debug("<WebAuthnClient> adjustLifetimeTimer")
        // TODO assert self.maxTimeout > self.minTimeout
        if let t = timeout {
            if (t < self.minTimeout) {
                return self.minTimeout
            }
            if (t > self.maxTimeout) {
                return self.maxTimeout
            }
            return t
        } else {
            return self.defaultTimeout
        }
    }

    /// this function comforms to https://www.w3.org/TR/webauthn/#createCredential
    /// 5.1.3 - 7 If options.rpId is not present, then set rpId to effectiveDomain.
    private func pickRelyingPartyID(_ rpId: String?) -> String {

        WAKLogger.debug("<WebAuthnClient> pickRelyingPartyID")

        if let _rpId = rpId {
            return _rpId
        } else {
            // TODO take EffectiveDomain from origin, properly.
            return self.origin
        }
    }

    // 5.1.3 - 13,14,15 Prepare ClientData, JSON, Hash
    private func generateClientData(
        type:      CollectedClientDataType,
        challenge: String
        ) -> (CollectedClientData, String, [UInt8]) {

        WAKLogger.debug("<WebAuthnClient> generateClientData")

        // TODO TokenBinding
        let clientData = CollectedClientData(
            type:         type,
            challenge:    challenge,
            origin:       self.origin,
            tokenBinding: nil
        )

        let clientDataJSONData = try! JSONEncoder().encode(clientData)
        let clientDataJSON = String(data: clientDataJSONData, encoding: .utf8)!
        let clientDataHash = clientDataJSON.bytes.sha256()

        return (clientData, clientDataJSON, clientDataHash)
    }

}

