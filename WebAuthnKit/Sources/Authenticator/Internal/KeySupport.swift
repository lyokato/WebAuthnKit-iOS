//
//  KeySupport.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import CryptoSwift
import SwiftyRSA
import EllipticCurveKeyPair

public protocol KeySupport {
    var selectedAlg: COSEAlgorithmIdentifier { get }
    func canHandle(alg: Int) -> Bool
    func createKeyPair(label: String) -> Optional<COSEKey>
    func sign(data: [UInt8], label: String) -> Optional<[UInt8]>
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
            case COSEAlgorithmIdentifier.es384:
                return ECDSAKeySupport(alg: .es384)
            case COSEAlgorithmIdentifier.es512:
                return ECDSAKeySupport(alg: .es512)
            default:
                WAKLogger.debug("<KeySupportChooser> currently this algorithm not supported")
                return nil
            }
        }

        return nil
    }
}

public class ECDSAKeySupport : KeySupport {
    
    public static let algorithms: [COSEAlgorithmIdentifier] = [.es256, .es384, .es512]
    
    public func canHandle(alg: Int) -> Bool {
        WAKLogger.debug("<ECDSAKeySupport> canHandle")
        return type(of: self).algorithms.contains { $0.rawValue == alg }
    }
    
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
            flags:      [.privateKeyUsage]
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
    
    public func sign(data: [UInt8], label: String) -> Optional<[UInt8]> {
        do {
            let pair = self.createPair(label: label)
            let signature = try pair.sign(Data(bytes: data), hash: self.getDigestType())
            return signature.bytes
        } catch let error {
            WAKLogger.debug("<ECDSAKeySupport> failed to sign: \(error)")
            return nil
        }
    }
    
    private func getDigestType() -> EllipticCurveKeyPair.Hash {
        switch selectedAlg {
        case .es256:
            return .sha256
        case .es384:
            return .sha384
        case .es512:
            return .sha512
        default:
            fatalError("must not come here")
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
