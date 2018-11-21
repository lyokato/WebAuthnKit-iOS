//
//  AuthenticatorData.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation

public struct AttestedCredentialData {

    let aaguid:              [UInt8] // 16byte
    let credentialId:        [UInt8]
    let credentialPublicKey: COSEKey // COSE_Key

    public func toBytes() -> [UInt8] {
        if self.aaguid.count != 16 {
           fatalError("<AttestedCredentialData> invalid aaguid length")
        }
        var result = self.aaguid
        let credentialIdLength = credentialId.count
        result.append(UInt8((credentialIdLength & 0xff00) >> 8))
        result.append(UInt8((credentialIdLength & 0x00ff)))
        result.append(contentsOf: credentialId)
        result.append(contentsOf: credentialPublicKey.toBytes())
        return result
    }
}

public struct AuthenticatorData {

    public static func fromBytes(_ bytes: [UInt8]) -> Optional<AuthenticatorData> {
        if bytes.count < 37 {
            WAKLogger.debug("<AuthenticatorData> byte-size is not enough")
            return nil
        }
        let rpIdHash: [UInt8] = Array(bytes[0..<32])

        let flags: UInt8 = bytes[32]

        let userPresent               = ((flags & 0b10000000) == 0b10000000)
        let userVerified              = ((flags & 0b00100000) == 0b00100000)
        let hasAttestedCredentialData = ((flags & 0b00000010) == 0b00000010)
        let hasExtension              = ((flags & 0b00000001) == 0b00000001)

        let signCount = UInt32((UInt32(bytes[33]) << 24) | (UInt32(bytes[34]) << 16) | (UInt32(bytes[35]) << 8) | UInt32(bytes[36]))

        var pos = 37

        var attestedCredentialData: AttestedCredentialData? = nil

        if hasAttestedCredentialData {

            if bytes.count < (pos + 16 + 2) {
                WAKLogger.debug("<AuthenticatorData> byte-size is not enough")
                return nil
            }

            let aaguid = Array(bytes[pos..<(pos+16)])

            pos = pos + 16

            let len = Int((UInt16(bytes[pos]) << 8) | UInt16(bytes[pos+1]))

            pos = pos + 2

            if bytes.count < (pos + len) {
                WAKLogger.debug("<AuthenticatorData> byte-size is not enough")
                return nil
            }

            let credentialId = Array(bytes[pos..<(pos+len)])

            pos = pos + len

            let rest = Array(bytes[pos..<bytes.count])

            guard let (coseKey, readSize) = COSEKeyParser.parse(bytes: rest) else {
                WAKLogger.debug("<AuthenticatorData> failed to parse COSE_Key")
                return nil
            }

            attestedCredentialData = AttestedCredentialData(
                aaguid:              aaguid,
                credentialId:        credentialId,
                credentialPublicKey: coseKey
            )

            pos = pos + readSize

        }

        var extensions = SimpleOrderedDictionary<String>()

        if hasExtension {

            let rest = Array(bytes[pos..<bytes.count])

            guard let params = CBORReader(bytes: rest).readStringKeyMap() else {
                WAKLogger.debug("<AuthenticatorData> failed to read CBOR for extensions")
                return nil
            }

            extensions = SimpleOrderedDictionary<String>.fromDictionary(params)
        }

        return AuthenticatorData(
            rpIdHash:               rpIdHash,
            userPresent:            userPresent,
            userVerified:           userVerified,
            signCount:              signCount,
            attestedCredentialData: attestedCredentialData,
            extensions:             extensions
        )

    }

    let rpIdHash:               [UInt8]
    let userPresent:            Bool
    let userVerified:           Bool
    let signCount:              UInt32
    let attestedCredentialData: AttestedCredentialData?
    let extensions:             SimpleOrderedDictionary<String>;

    public func toBytes() -> [UInt8] {

        if self.rpIdHash.count != 32 {
            fatalError("<AuthenticatorData> rpIdHash should be 32 bytes")
        }

        var result = self.rpIdHash

        var flags: UInt8 = 0b00000000
        if self.userPresent {
            flags = flags | 0b10000000
        }
        if self.userVerified {
            flags = flags | 0b00100000
        }
        if self.attestedCredentialData != nil {
            flags = flags | 0b00000010
        }
        if !self.extensions.isEmpty {
            flags = flags | 0b00000001
        }
        result.append(flags)

        result.append(UInt8((signCount & 0xff000000) >> 24))
        result.append(UInt8((signCount & 0x00ff0000) >> 16))
        result.append(UInt8((signCount & 0x0000ff00) >>  8))
        result.append(UInt8((signCount & 0x000000ff)))

        if let attestedData = self.attestedCredentialData {
            result.append(contentsOf: attestedData.toBytes())
        }

        if !self.extensions.isEmpty {
            let builder = CBORWriter()
            _ = builder.putStringKeyMap(self.extensions)
            result.append(contentsOf: builder.getResult())
        }

        return result
    }
}
