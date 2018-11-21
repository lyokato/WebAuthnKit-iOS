//
//  UserConsent.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/20.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import Foundation
import LocalAuthentication

import PromiseKit
import CryptoSwift

public enum UserHandleDisplayType {
    case utf8String
    case number
}

public class UserConsentUI {

    public typealias MessageBuilder = ((PublicKeyCredentialRpEntity ,PublicKeyCredentialUserEntity) -> String)

    private let viewController: UIViewController

    public var newCredentialPopupTitle: String = "New Authentication Key"
    public var newCredentialPopupMessage: String = "key for this service already exists, do you surely create new one?"

    public var confirmationPopupTitle: String = "New Authentication Key"
    public var confirmationPopupMessageBuilder: MessageBuilder = { rp, user in
        return "Create new key for \(user.displayName)?"
    }

    public var selectionPopupTitle: String = "Login Key Selection"
    public var selectionPopupMessage: String = "Choose key with which you want to login with"

    public var userHandleDisplayType: UserHandleDisplayType = .number

    public init(viewController: UIViewController) {
        self.viewController = viewController
    }

    internal func askUserToCreateNewCredential(rpId: String) -> Promise<()> {

        return Promise { resolver in

            DispatchQueue.main.async {

                let alert = UIAlertController.init(
                    title:          self.newCredentialPopupTitle,
                    message:        self.newCredentialPopupMessage,
                    preferredStyle: .actionSheet
                )

                let okAction = UIAlertAction.init(title: "OK", style: .default) { _ in
                    DispatchQueue.global().async {
                        resolver.fulfill(())
                    }
                }

                let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel) { _ in
                    DispatchQueue.global().async {
                        resolver.reject(AuthenticatorError.notAllowedError)
                    }
                }

                alert.addAction(okAction)
                alert.addAction(cancelAction)

                self.viewController.present(alert, animated: true, completion: nil)
            }

        }

    }

    internal func requestUserConsent(
        rpEntity:            PublicKeyCredentialRpEntity,
        userEntity:          PublicKeyCredentialUserEntity,
        requireVerification: Bool
        ) -> Promise<()> {

        let message = self.confirmationPopupMessageBuilder(rpEntity, userEntity)

        if requireVerification {

            return self.verifyUser(message: message)

        } else {

            return Promise { resolver in

                DispatchQueue.main.async {

                    let alert = UIAlertController.init(
                        title:          self.confirmationPopupTitle,
                        message:        message,
                        preferredStyle: .actionSheet
                    )

                    let okAction = UIAlertAction.init(title: "OK", style: .default) { _ in
                        DispatchQueue.global().async {
                            resolver.fulfill(())
                        }
                    }

                    let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel) { _ in
                        DispatchQueue.global().async {
                            resolver.reject(AuthenticatorError.notAllowedError)
                        }
                    }

                    alert.addAction(okAction)
                    alert.addAction(cancelAction)

                    self.viewController.present(alert, animated: true, completion: nil)
                }
            }
        }
    }

    internal func requestUserSelection(
        credentials:         [PublicKeyCredentialSource],
        requireVerification: Bool
        ) -> Promise<PublicKeyCredentialSource> {

        if requireVerification {

            let message = self.selectionPopupMessage
            return self.verifyUser(message: message).then {
                return self.requestUserSelectionInternal(credentials: credentials)
            }

        } else {

           return self.requestUserSelectionInternal(credentials: credentials)

        }
    }

    internal func requestUserSelectionInternal(
        credentials: [PublicKeyCredentialSource]
    ) -> Promise<PublicKeyCredentialSource> {

        return Promise { resolver in

            DispatchQueue.main.async {

                let alert = UIAlertController.init(
                    title:   self.selectionPopupTitle,
                    message: self.selectionPopupMessage,
                    preferredStyle: .actionSheet)

                credentials.forEach { src in
                    var title = self.getUserHandleDisplay(src.userHandle)
                    if let other = src.otherUI {
                        title = "\(title) (\(other))"
                    }
                    let chooseAction = UIAlertAction.init(title: title, style: .destructive) { _ in
                        DispatchQueue.global().async {
                            resolver.fulfill(src)
                        }
                    }

                    alert.addAction(chooseAction)
                }

                let cancelAction = UIAlertAction.init(title: "Cancel", style: .cancel) { _ in
                    DispatchQueue.global().async {
                        resolver.reject(AuthenticatorError.notAllowedError)
                    }
                }
                alert.addAction(cancelAction)

                self.viewController.present(alert, animated: true, completion: nil)
            }
        }
    }

    private func verifyUser(message: String) -> Promise<()> {

        return Promise { resolver in

            DispatchQueue.main.async {

                let ctx = LAContext()

                if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
                    ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                       localizedReason: message,
                                       reply: { success, error in
                                        if success {
                                            DispatchQueue.global().async {
                                                resolver.fulfill(())
                                            }
                                        } else if let error = error {
                                            switch LAError(_nsError: error as NSError) {
                                            case LAError.userCancel:
                                                WAKLogger.debug("<UserConsentUI> user cancel")
                                                self.dispatchError(resolver, .notAllowedError)
                                            case LAError.userFallback:
                                                WAKLogger.debug("<UserConsentUI> user fallback")
                                                self.dispatchError(resolver, .notAllowedError)
                                            case LAError.authenticationFailed:
                                                WAKLogger.debug("<UserConsentUI> authentication failed")
                                                self.dispatchError(resolver, .notAllowedError)
                                            case LAError.passcodeNotSet:
                                                WAKLogger.debug("<UserConsentUI> passcode not set")
                                                self.dispatchError(resolver, .notAllowedError)
                                            case LAError.systemCancel:
                                                WAKLogger.debug("<UserConsentUI> system cancel")
                                                self.dispatchError(resolver, .notAllowedError)
                                            default:
                                                WAKLogger.debug("<UserConsentUI> must not come here")
                                                self.dispatchError(resolver, .unknownError)
                                            }

                                        } else {
                                            WAKLogger.debug("<UserConsentUI> must not come here")
                                            self.dispatchError(resolver, .unknownError)
                                        }
                    })
                } else {
                    WAKLogger.debug("<UserConsentUI> Device not supported")
                    self.dispatchError(resolver, .notAllowedError)
                }
            }
        }
    }
    
    private func dispatchError(_ resolver: Resolver<()>, _ error: AuthenticatorError) {
        DispatchQueue.global().async {
            resolver.reject(error)
        }
    }

    private func getUserHandleDisplay(_ userHandle: [UInt8]) -> String {
        switch self.userHandleDisplayType {
        case .number:
            return Bytes.toUInt64(userHandle).description
        case .utf8String:
            if let result = String(data: Data(bytes: userHandle), encoding: .utf8) {
                return result
            } else {
                return "--"
            }
        }
    }
}
