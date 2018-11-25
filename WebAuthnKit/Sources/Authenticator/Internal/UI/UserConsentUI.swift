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

public protocol UserConsentViewControllerDelegate: class {
    func consentViewControllerWillDismiss(viewController: UIViewController)
}

public class UserConsentUI: UserConsentViewControllerDelegate {
    
    public typealias MessageBuilder = ((PublicKeyCredentialRpEntity ,PublicKeyCredentialUserEntity) -> String)

    private let viewController: UIViewController
    public let config = UserConsentUIConfig()

    private let tempBackground: UIView

    public init(viewController: UIViewController) {
        self.viewController = viewController
        self.tempBackground = UIView()
        self.tempBackground.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.tempBackground.backgroundColor = UIColor.black
        self.tempBackground.alpha = 0
    }
    
    public func cancel() {
        DispatchQueue.main.async {
            // if let ctx = self.laCtx {
            //    ctx.invalidate()
            // }
            // if let alert = self.popup {
            //    alert.dismiss(animated: true, completion: nil)
            // }
            self.clear()
        }
    }
    
    private func clear() {
        // self.laCtx = nil
        // self.popup = nil
    }

    internal func askUserToCreateNewCredential(rpId: String) -> Promise<()> {
        
        WAKLogger.debug("<UserConsentUI> askUserToCreateNewCredential")

        return Promise { resolver in

            DispatchQueue.main.async {

                let alert = UIAlertController.init(
                    title:          self.config.excludeKeyFoundPopupTitle,
                    message:        self.config.excludeKeyFoundPopupMessage,
                    preferredStyle: .actionSheet
                )

                let okAction = UIAlertAction.init(title: self.config.excludeKeyFoundPopupCreateButtonText, style: .default) { _ in
                    DispatchQueue.global().async {
                        resolver.fulfill(())
                    }
                }

                let cancelAction = UIAlertAction.init(title: self.config.excludeKeyFoundPopupCancelButtonText, style: .cancel) { _ in
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
        ) -> Promise<String> {
        
        WAKLogger.debug("<UserConsentUI> requestUserConsent")
        
        let promise = Promise<String> { resolver in
            
            DispatchQueue.main.async {
            
                let vc = KeyRegistrationViewController(
                    resolver:          resolver,
                    config:            self.config,
                    user:              userEntity,
                    rp:                rpEntity
                )
                
                vc.delegate = self
                
                self.showBackground()
                
                self.viewController.present(vc, animated: true, completion: nil)
                
            }
            
        }
        
        if requireVerification {
            return promise.then {
                return self.verifyUser(message: "Create-Key Authentication", params: $0)
            }
        } else {
            return promise
        }
    }
    
    public func consentViewControllerWillDismiss(viewController: UIViewController) {
        self.hideBackground()
    }
    
    private func showBackground() {
        self.viewController.view.addSubview(self.tempBackground)
        self.tempBackground.frame = self.viewController.view.frame
        UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseIn], animations: {
            self.tempBackground.alpha = 0.4
        }, completion: nil)
    }
    
    private func hideBackground() {
        if self.tempBackground.superview != nil {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseIn], animations: {
                self.tempBackground.alpha = 0.0
            }, completion: { _ in
                self.tempBackground.removeFromSuperview()
            })
        }
    }

    internal func requestUserSelection(
        sources:             [PublicKeyCredentialSource],
        requireVerification: Bool
        ) -> Promise<PublicKeyCredentialSource> {
        
        WAKLogger.debug("<UserConsentUI> requestUserSelection")
        let promise = Promise<PublicKeyCredentialSource> { resolver in
            
            DispatchQueue.main.async {
                
                let vc = KeySelectionViewController(
                    resolver: resolver,
                    config:   self.config,
                    sources:  sources
                )
                
                vc.delegate = self
                
                self.showBackground()
                
                self.viewController.present(vc, animated: true, completion: nil)
                
            }
            
        }
        
        if requireVerification {
            return promise.then {
                return self.verifyUser(message: "Use-Key Authentication", params: $0)
            }
        } else {
            return promise
        }
    }
    
    private func verifyUser<T>(message: String, params: T) -> Promise<T> {
        
        WAKLogger.debug("<UserConsentUI> verifyUser")

        return Promise<T> { resolver in

            DispatchQueue.main.async {

                let ctx = LAContext()
                var authError: NSError?
                //if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
                //    ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                if ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
                    ctx.evaluatePolicy(.deviceOwnerAuthentication,
                                       localizedReason: message,
                                       reply: { success, error in
                                        if success {
                                            DispatchQueue.global().async {
                                                resolver.fulfill(params)
                                            }
                                        } else if let error = error {
                                            switch LAError(_nsError: error as NSError) {
                                            case LAError.userFallback:
                                                WAKLogger.debug("<UserConsentUI> user fallback")
                                                self.dispatchError(resolver, .notAllowedError)
                                            case LAError.userCancel:
                                                WAKLogger.debug("<UserConsentUI> user cancel")
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
                    let reason = authError?.localizedDescription ?? ""
                    WAKLogger.debug("<UserConsentUI> device not supported: \(reason)")
                    self.dispatchError(resolver, .notAllowedError)
                }
            }
        }
    }
    
    private func dispatchError<T>(_ resolver: Resolver<T>, _ error: AuthenticatorError) {
        WAKLogger.debug("<UserConsentUI> dispatchError")
        DispatchQueue.global().async {
            resolver.reject(error)
        }
    }

}
