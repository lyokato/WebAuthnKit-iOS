//
//  KeySupport.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import CryptoSwift
import EllipticCurveKeyPair
import LocalAuthentication

public protocol KeySupport {
    var selectedAlg: COSEAlgorithmIdentifier { get }
    func createKeyPair(label: String) -> Optional<COSEKey>
    func sign(data: [UInt8], label: String, context: LAContext) -> Optional<[UInt8]>
}

public class KeySupportChooser {
    
    public init() {}

    public func choose(_ requestedAlgorithms: [COSEAlgorithmIdentifier])
        -> Optional<KeySupport> {
        WAKLogger.debug("<KeySupportChooser> choose")

        for alg in requestedAlgorithms {
            switch alg {
            case COSEAlgorithmIdentifier.es256:
                return ECDSAKeySupport(alg: .es256)
            default:
                WAKLogger.debug("<KeySupportChooser> currently this algorithm not supported")
                return nil
            }
        }

        return nil
    }
}

public class ECDSAKeySupport : KeySupport {
    
    public let selectedAlg: COSEAlgorithmIdentifier
    
    init(alg: COSEAlgorithmIdentifier) {
        self.selectedAlg = alg
    }
    
    private func createPair(label: String) -> EllipticCurveKeyPair.Manager {
        let publicAccessControl = EllipticCurveKeyPair.AccessControl(
            protection: kSecAttrAccessibleAlwaysThisDeviceOnly,
            flags:      []
        )
        let privateAccessControl = EllipticCurveKeyPair.AccessControl(
            protection: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            flags:      [.userPresence, .privateKeyUsage]
        )
        let config = EllipticCurveKeyPair.Config(
            publicLabel:             "\(label)/public",
            privateLabel:            "\(label)/private",
            operationPrompt:         "KeyPair",
            publicKeyAccessControl:  publicAccessControl,
            privateKeyAccessControl: privateAccessControl,
            token:                   EllipticCurveKeyPair.Token.secureEnclaveIfAvailable
        )
        return EllipticCurveKeyPair.Manager(config: config)
    }
    
    public func sign(data: [UInt8], label: String, context: LAContext) -> Optional<[UInt8]> {
        do {
            let pair = self.createPair(label: label)
            let signature = try pair.sign(Data(bytes: data), hash: .sha256, context: context)
            return signature.bytes
        } catch let error {
            WAKLogger.debug("<ECDSAKeySupport> failed to sign: \(error)")
            return nil
        }
    }
    
    public func createKeyPair(label: String) -> Optional<COSEKey> {
        WAKLogger.debug("<ECDSAKeySupport> createKeyPair")
        do {
            let pair = self.createPair(label: label)
            let publicKey = try pair.publicKey().data().DER.bytes
            if publicKey.count != 91 {
                WAKLogger.debug("<ECDSAKeySupport> length of pubKey should be 91: \(publicKey.count)")
                return nil
            }
            
            let x = Array(publicKey[27..<59])
            let y = Array(publicKey[59..<91])
            
            let key: COSEKey = COSEKeyEC2(
                alg: self.selectedAlg.rawValue,
                crv: COSEKeyCurveType.p256,
                xCoord: x,
                yCoord: y
            )
            return key
            
        } catch let error {
            WAKLogger.debug("<ECDSAKeySupport> failed to create key-pair: \(error)")
            return nil
        }
    }
}
