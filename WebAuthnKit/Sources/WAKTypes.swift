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
    var clientDataJSON: String
    var attestationObject: [UInt8]
}

public struct AuthenticatorAssertionResponse: AuthenticatorResponse {
    var clientDataJSON: String
    var authenticatorData: [UInt8]
    var signature: [UInt8]
    var userHandler: [UInt8]?
}

public struct PublicKeyCredential<T: AuthenticatorResponse>: Codable {
    let type: PublicKeyCredentialType = .publicKey
    var rawId: [UInt8]
    var id: String
    var response: T
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
    var type: PublicKeyCredentialType = .publicKey
    var id: [UInt8] = [UInt8]() // credential ID
    var transports = [AuthenticatorTransport]()
}

public struct PublicKeyCredentialRpEntity: Codable {
    var id: String?
    var name: String = ""
    var icon: String?
}

public struct PublicKeyCredentialUserEntity: Codable {
    var id: [UInt8] = [UInt8]()
    var displayName: String = ""
    var name: String = ""
    var icon: String?
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
    let type: PublicKeyCredentialType = .publicKey
    var alg: Int
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
    var status: TokenBindingStatus
    var id: String
}

public enum CollectedClientDataType: String, Codable {
    case webAuthnCreate = "webauthn.create"
    case webAuthnGet = "webauthn.get"
}

public struct CollectedClientData : Codable {
    var type: CollectedClientDataType
    var challenge: String
    var origin: String
    var tokenBinding: TokenBinding?
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
    var authenticatorAttachment: AuthenticatorAttachment?
    var requireResidentKey: Bool = false
    var userVerification: UserVerificationRequirement = .preferred
}

// put extensions supported in this library
public struct ExtensionOptions: Codable {

}

public struct PublicKeyCredentialCreationOptions: Codable {
    var rp: PublicKeyCredentialRpEntity = PublicKeyCredentialRpEntity()
    var user: PublicKeyCredentialUserEntity = PublicKeyCredentialUserEntity()
    var challenge: String = ""
    var pubKeyCredParams = [PublicKeyCredentialParameters]()
    var timeout: UInt64?
    var excludeCredentials = [PublicKeyCredentialDescriptor]()
    var authenticatorSelection: AuthenticatorSelectionCriteria?
    var attestation: AttestationConveyancePreference = .none
    var extensions: ExtensionOptions?
    
    public static func fromJSON(json: String) -> Optional<PublicKeyCredentialCreationOptions> {
        guard let args = JSONHelper<PublicKeyCredentialCreationArgs>.decode(json) else {
            return nil
        }
        return args.publicKey
    }
}

public struct PublicKeyCredentialRequestOptions: Codable {
    var challenge: String = ""
    var timeout: UInt64?
    var rpId: String?
    var allowCredentials = [PublicKeyCredentialDescriptor]()
    var userVerification: UserVerificationRequirement = .preferred
    // let extensions: []
    public static func fromJSON(json: String) -> Optional<PublicKeyCredentialRequestOptions> {
        guard let args = JSONHelper<PublicKeyCredentialRequestArgs>.decode(json) else {
            return nil
        }
        return args.publicKey
    }
}

public struct PublicKeyCredentialCreationArgs: Codable {
    let publicKey: PublicKeyCredentialCreationOptions
}

public struct PublicKeyCredentialRequestArgs: Codable {
    let publicKey: PublicKeyCredentialRequestOptions
}
