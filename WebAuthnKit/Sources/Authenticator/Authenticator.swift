//
//  Authenticator.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation

public struct AuthenticatorAssertionResult {
    var credentailId: [UInt8]?
    var userHandle: [UInt8]?
    var signature: [UInt8]
    var authenticatorData: [UInt8]
    init(authenticatorData: [UInt8], signature: [UInt8]) {
        self.authenticatorData = authenticatorData
        self.signature = signature
    }
}

public protocol AuthenticatorMakeCredentialSessionDelegate: class {
    func authenticatorSessionDidBecomeAvailable(session: AuthenticatorMakeCredentialSession)
    func authenticatorSessionDidBecomeUnavailable(session: AuthenticatorMakeCredentialSession)
    func authenticatorSessionDidStopOperation(session: AuthenticatorMakeCredentialSession, reason: WAKError)
    func authenticatorSessionDidMakeCredential(session: AuthenticatorMakeCredentialSession, attestation: AttestationObject)
}

public protocol AuthenticatorGetAssertionSessionDelegate: class {
    func authenticatorSessionDidBecomeAvailable(session: AuthenticatorGetAssertionSession)
    func authenticatorSessionDidBecomeUnavailable(session: AuthenticatorGetAssertionSession)
    func authenticatorSessionDidStopOperation(session: AuthenticatorGetAssertionSession, reason: WAKError)
    func authenticatorSessionDidDiscoverCredential(session: AuthenticatorGetAssertionSession, assertion: AuthenticatorAssertionResult)
}

public protocol AuthenticatorGetAssertionSession {
    
    var attachment: AuthenticatorAttachment { get }
    var transport: AuthenticatorTransport { get }
    
    var delegate: AuthenticatorGetAssertionSessionDelegate? { set get }
    
    func getAssertion(
        rpId: String,
        hash:                          [UInt8],
        allowCredentialDescriptorList: [PublicKeyCredentialDescriptor],
        requireUserPresence:           Bool,
        requireUserVerification:       Bool
        // extensions: []
    )
    
    func canPerformUserVerification() -> Bool
    
    func start()
    func cancel(reason: WAKError)

}

public protocol AuthenticatorMakeCredentialSession {
    
    var attachment: AuthenticatorAttachment { get }
    var transport: AuthenticatorTransport { get }
    
    var delegate: AuthenticatorMakeCredentialSessionDelegate? { set get }

    func makeCredential(
        hash:                            [UInt8],
        rpEntity:                        PublicKeyCredentialRpEntity,
        userEntity:                      PublicKeyCredentialUserEntity,
        requireResidentKey:              Bool,
        requireUserPresence:             Bool,
        requireUserVerification:         Bool,
        credTypesAndPubKeyAlgs:          [PublicKeyCredentialParameters],
        excludeCredentialDescriptorList: [PublicKeyCredentialDescriptor]
    )
    
    func canPerformUserVerification() -> Bool
    func canStoreResidentKey() -> Bool
    
    func start()
    func cancel(reason: WAKError)

}

public protocol Authenticator {

    var attachment: AuthenticatorAttachment { get }
    var transport: AuthenticatorTransport { get }
    
    var counterStep: UInt32 { set get }
    var allowResidentKey: Bool { get }
    var allowUserVerification: Bool { get }
    
    func newMakeCredentialSession() -> AuthenticatorMakeCredentialSession
    func newGetAssertionSession() -> AuthenticatorGetAssertionSession

}

