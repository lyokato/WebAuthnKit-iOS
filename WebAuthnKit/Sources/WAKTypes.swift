//
//  WAKTypes.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation

public enum WAKError : Error {
    case badData
    case badOperation
    case invalidState
    case constraint
    case cancelled
    case timeout
    case notAllowed
    case unsupported
    case unknown
}

public enum WAKResult<T, Error: Swift.Error> {
    case success(T)
    case failure(Error)
}

public enum PublicKeyCredentialType: String, Codable {
    case publicKey = "public-key"
}

public enum UserVerificationRequirement: String, Codable {

    case required
    case preferred
    case discouraged

    public static func ==(
        lhs: UserVerificationRequirement,
        rhs: UserVerificationRequirement) -> Bool {

        switch (lhs, rhs) {
        case (.required, .required):
            return true
        case (.preferred, .preferred):
            return true
        case (.discouraged, .discouraged):
            return true
        default:
            return false
        }

    }
}

public protocol AuthenticatorResponse : Codable {}
public struct AuthenticatorAttestationResponse : AuthenticatorResponse {
    public var clientDataJSON: String
    public var attestationObject: [UInt8]
}

public struct AuthenticatorAssertionResponse: AuthenticatorResponse {
    public var clientDataJSON: String
    public var authenticatorData: [UInt8]
    public var signature: [UInt8]
    public var userHandle: [UInt8]?
}

public struct PublicKeyCredential<T: AuthenticatorResponse>: Codable {
    public var type: PublicKeyCredentialType = .publicKey
    public var rawId: [UInt8]
    public var id: String
    public var response: T
    // getClientExtensionResults()
    
    public func toJSON() -> Optional<String> {
       return JSONHelper<PublicKeyCredential<T>>.encode(self)
    }
}

public enum AuthenticatorTransport: String, Codable, Equatable {
    case usb
    case nfc
    case ble
    case internal_ = "internal"

    public static func ==(
        lhs: AuthenticatorTransport,
        rhs: AuthenticatorTransport) -> Bool {

        switch (lhs, rhs) {
        case (.usb, .usb):
            return true
        case (.nfc, .nfc):
            return true
        case (.ble, .ble):
            return true
        case (.internal_, .internal_):
            return true
        default:
            return false
        }
    }
}

public struct PublicKeyCredentialDescriptor: Codable {
    
    public var type: PublicKeyCredentialType = .publicKey
    public var id: [UInt8] // credential ID
    public var transports: [AuthenticatorTransport]
    
    public init(
        id:         [UInt8]                  = [UInt8](),
        transports: [AuthenticatorTransport] = [AuthenticatorTransport]()
    ) {
        self.id         = id
        self.transports = transports
    }

    public mutating func addTransport(transport: AuthenticatorTransport) {
       self.transports.append(transport)
    }
}

public struct PublicKeyCredentialRpEntity: Codable {
    
    public var id: String?
    public var name: String
    public var icon: String?
    
    public init(
        id: String? = nil,
        name: String = "",
        icon: String? = nil
    ) {
        self.id   = id
        self.name = name
        self.icon = icon
    }
}

public struct PublicKeyCredentialUserEntity: Codable {
    
    public var id: [UInt8]
    public var displayName: String
    public var name: String
    public var icon: String?
    
    public init(
        id: [UInt8] = [UInt8](),
        displayName: String = "",
        name: String = "",
        icon: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.name = name
        self.icon = icon
    }
}

public enum AttestationConveyancePreference: String, Codable {
    case none
    case direct
    case indirect

    public static func ==(
        lhs: AttestationConveyancePreference,
        rhs: AttestationConveyancePreference) -> Bool {

        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.direct, .direct):
            return true
        case (.indirect, .indirect):
            return true
        default:
            return false
        }
    }
}

public struct PublicKeyCredentialParameters : Codable {
    public var type: PublicKeyCredentialType = .publicKey
    public var alg: COSEAlgorithmIdentifier
    
    public init(alg: COSEAlgorithmIdentifier) {
        self.alg = alg
    }
}

public enum TokenBindingStatus: String, Codable {

    case present
    case supported

    public static func ==(
        lhs: TokenBindingStatus,
        rhs: TokenBindingStatus) -> Bool{

        switch (lhs, rhs) {
        case (.present, .present):
            return true
        case (.supported, .supported):
            return true
        default:
            return false
        }
    }
}

public struct TokenBinding: Codable {
    public var status: TokenBindingStatus
    public var id: String
    
    public init(id: String, status: TokenBindingStatus) {
        self.id = id
        self.status = status
    }
}

public enum CollectedClientDataType: String, Codable {
    case webAuthnCreate = "webauthn.create"
    case webAuthnGet = "webauthn.get"
}

public struct CollectedClientData : Codable {
    public var type: CollectedClientDataType
    public var challenge: String
    public var origin: String
    public var tokenBinding: TokenBinding?
}

public enum AuthenticatorAttachment: String, Codable {
    case platform
    case crossPlatform = "cross-platform"

    public static func ==(
        lhs: AuthenticatorAttachment,
        rhs: AuthenticatorAttachment) -> Bool {
        switch (lhs, rhs) {
        case (.platform, .platform):
            return true
        case (.crossPlatform, .crossPlatform):
            return true
        default:
            return false
        }
    }
}

public struct AuthenticatorSelectionCriteria: Codable {
    
    public var authenticatorAttachment: AuthenticatorAttachment?
    public var requireResidentKey: Bool
    public var userVerification: UserVerificationRequirement
    
    public init(
        authenticatorAttachment: AuthenticatorAttachment? = nil,
        requireResidentKey: Bool = true,
        userVerification: UserVerificationRequirement = .preferred
    ) {
        self.authenticatorAttachment = authenticatorAttachment
        self.requireResidentKey = requireResidentKey
        self.userVerification = userVerification
    }
}

// put extensions supported in this library
public struct ExtensionOptions: Codable {

}

public struct PublicKeyCredentialCreationOptions: Codable {
    
    public var rp: PublicKeyCredentialRpEntity
    public var user: PublicKeyCredentialUserEntity
    public var challenge: [UInt8]
    public var pubKeyCredParams: [PublicKeyCredentialParameters]
    public var timeout: UInt64?
    public var excludeCredentials: [PublicKeyCredentialDescriptor]
    public var authenticatorSelection: AuthenticatorSelectionCriteria?
    public var attestation: AttestationConveyancePreference
    public var extensions: ExtensionOptions?
    
    public init(
        rp: PublicKeyCredentialRpEntity = PublicKeyCredentialRpEntity(),
        user: PublicKeyCredentialUserEntity = PublicKeyCredentialUserEntity(),
        challenge: [UInt8] = [UInt8](),
        pubKeyCredParams: [PublicKeyCredentialParameters] = [PublicKeyCredentialParameters](),
        timeout: UInt64? = nil,
        excludeCredentials: [PublicKeyCredentialDescriptor] = [PublicKeyCredentialDescriptor](),
        authenticatorSelection: AuthenticatorSelectionCriteria? = nil,
        attestation: AttestationConveyancePreference = .none
    ) {
        self.rp = rp
        self.user = user
        self.challenge = challenge
        self.pubKeyCredParams = pubKeyCredParams
        self.timeout = timeout
        self.excludeCredentials = excludeCredentials
        self.authenticatorSelection = authenticatorSelection
        self.attestation = attestation
        // not supported yet
        self.extensions = nil
    }
    
    public mutating func addPubKeyCredParam(alg: COSEAlgorithmIdentifier) {
        self.pubKeyCredParams.append(PublicKeyCredentialParameters(alg: alg))
    }
    
    public func toJSON() -> Optional<String> {
        let obj = PublicKeyCredentialCreationArgs(publicKey: self)
        return JSONHelper<PublicKeyCredentialCreationArgs>.encode(obj)
    }
    
    public static func fromJSON(json: String) -> Optional<PublicKeyCredentialCreationOptions> {
        guard let args = JSONHelper<PublicKeyCredentialCreationArgs>.decode(json) else {
            return nil
        }
        return args.publicKey
    }
}

public struct PublicKeyCredentialRequestOptions: Codable {
    public var challenge: [UInt8]
    public var rpId: String?
    public var allowCredentials: [PublicKeyCredentialDescriptor]
    public var userVerification: UserVerificationRequirement
    public var timeout: UInt64?
    // let extensions: []
    
    public init(
        challenge: [UInt8] = [UInt8](),
        rpId: String = "",
        allowCredentials: [PublicKeyCredentialDescriptor] = [PublicKeyCredentialDescriptor](),
        userVerification: UserVerificationRequirement = .preferred,
        timeout: UInt64? = nil
    ) {
        self.challenge = challenge
        self.rpId = rpId
        self.allowCredentials = allowCredentials
        self.userVerification = userVerification
        self.timeout = timeout
    }
    
    public mutating func addAllowCredential(
        credentialId: [UInt8],
        transports: [AuthenticatorTransport]
    ) {
        self.allowCredentials.append(PublicKeyCredentialDescriptor(
            id:         credentialId,
            transports: transports
        ))
    }
    
    public func toJSON() -> Optional<String> {
        let obj = PublicKeyCredentialRequestArgs(publicKey: self)
        return JSONHelper<PublicKeyCredentialRequestArgs>.encode(obj)
    }
    
    public static func fromJSON(json: String) -> Optional<PublicKeyCredentialRequestOptions> {
        guard let args = JSONHelper<PublicKeyCredentialRequestArgs>.decode(json) else {
            return nil
        }
        return args.publicKey
    }
}

public struct PublicKeyCredentialCreationArgs: Codable {
    public let publicKey: PublicKeyCredentialCreationOptions
}

public struct PublicKeyCredentialRequestArgs: Codable {
    public let publicKey: PublicKeyCredentialRequestOptions
}
