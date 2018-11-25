//
//  KeySelectionViewController.swift
//  WebAuthnKit
//
//  Created by Lyo Kato on 2018/11/22.
//  Copyright © 2018 Lyo Kato. All rights reserved.
//

import UIKit
import PromiseKit

public protocol KeySelectionViewDelegate: class {
    func userDidSelectCredential(source: PublicKeyCredentialSource)
    func userDidCancel()
}

public class KeySelectionView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {
    
    weak var delegate: KeySelectionViewDelegate?
    
    private var sources: [PublicKeyCredentialSource]
    private let config: UserConsentUIConfig
    
    init(config: UserConsentUIConfig, sources: [PublicKeyCredentialSource]) {
        self.config = config
        self.sources = sources
        super.init(frame: CGRect.zero)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func rgbColor(_ rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    private var pickerView: UIPickerView!
    
    private func setup() {
        
        let effect = UIBlurEffect(style: .prominent)
        let backgroundView = UIVisualEffectView(effect: effect)
        self.addSubview(backgroundView)
        
        self.layer.cornerRadius = 10.0
        self.clipsToBounds = true
        
        let verticalMargin: CGFloat  = 20
        let horizontalMargin: CGFloat = 50
        
        let minWidth: CGFloat = 320
        var viewWidth: CGFloat = UIScreen.main.bounds.width - horizontalMargin * 2
        viewWidth = min(minWidth, viewWidth)
        
        var offset: CGFloat = verticalMargin
        
        let wideLabelMargin: CGFloat = 10
        
        let titleHeight: CGFloat = 20
        let titleLabel = UILabel(frame: CGRect.zero)
        titleLabel.frame = CGRect(
            x: wideLabelMargin,
            y: offset,
            width: viewWidth - wideLabelMargin * 2,
            height: titleHeight
        )
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.black
        titleLabel.text = self.config.keySelectionTitle
        titleLabel.font = UIFont.systemFont(ofSize: 18.0, weight: .bold)
        titleLabel.textAlignment = .center
        self.addSubview(titleLabel)
        
        offset = offset + titleHeight + 16

        let pickerViewHeight: CGFloat = 140
        pickerView = UIPickerView(frame: CGRect.zero)
        pickerView.frame = CGRect(
            x: 0,
            y: offset,
            width: viewWidth,
            height: pickerViewHeight
        )
        
        pickerView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        pickerView.delegate = self
        pickerView.dataSource = self
        self.addSubview(pickerView)
        
        offset = offset + pickerViewHeight
        
        let buttonMargin: CGFloat = 0
        let buttonWidth = (viewWidth - buttonMargin * 3) / 2.0
        let buttonHeight: CGFloat = 50
        let cancelButton = UIButton()
        
        cancelButton.frame = CGRect(
            x: buttonMargin,
            y: offset,
            width: buttonWidth + 1,
            height: buttonHeight
        )
        cancelButton.setTitle(self.config.keySelectionCancelButtonText, for: .normal)
        cancelButton.setTitleColor(self.tintColor, for: .normal)
        cancelButton.layer.borderColor = self.rgbColor(0xbbbbbb).cgColor
        cancelButton.layer.borderWidth = 1.0
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .light)
        cancelButton.addTarget(
            self,
            action: #selector(KeySelectionView.onCancelButtonTapped(_:)),
            for: .touchUpInside
        )
        self.addSubview(cancelButton)
        
        let selectButton = UIButton()
        selectButton.frame = CGRect(
            x: buttonMargin * 2 + buttonWidth,
            y: offset,
            width: buttonWidth,
            height: buttonHeight
        )
        selectButton.setTitleColor(self.tintColor, for: .normal)
        selectButton.setTitle(self.config.keySelectionSelectButtonText, for: .normal)
        selectButton.layer.borderColor = self.rgbColor(0xbbbbbb).cgColor
        selectButton.layer.borderWidth = 1.0
        selectButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
        selectButton.addTarget(
            self,
            action: #selector(KeySelectionView.onSelectButtonTapped(_:)),
            for: .touchUpInside
        )
        self.addSubview(selectButton)
        
        offset = offset + buttonHeight
        
        self.frame = CGRect(
            x: 0,
            y: 0,
            width: viewWidth,
            height: offset
        )
        
        self.layer.borderColor = self.rgbColor(0xdddddd).cgColor
        self.layer.borderWidth = 1
        backgroundView.frame = self.frame
        
        WAKLogger.debug("<KeySelectionView> frame:\(viewWidth):\(offset)")
        
        self.selectedSource = self.sources[0]
    }
    
    @objc func onCancelButtonTapped(_ sender: UIButton) {
        self.delegate?.userDidCancel()
    }
    
    @objc func onSelectButtonTapped(_ sender: UIButton) {
        if let source = self.selectedSource {
            self.delegate?.userDidSelectCredential(source: source)
        } else {
            WAKLogger.debug("<KeySelectionView> no key selected")
        }
    }
    
    public func pickerView(
        _            pickerView: UIPickerView,
        viewForRow   row:        Int,
        forComponent component:  Int,
        reusing      view:       UIView?
    ) -> UIView {
        
        var pickerLabel: UILabel? = (view as? UILabel)
        
        if pickerLabel == nil {
            
            pickerLabel = UILabel()
            pickerLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            pickerLabel?.textAlignment = .center
            
        }
        let text = self.sources[row].otherUI
        pickerLabel?.text = text
        pickerLabel?.textColor = UIColor.black
        
        return pickerLabel!
    }

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.sources.count
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.sources[row].otherUI
    }
    
    var selectedSource: PublicKeyCredentialSource?
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedSource = self.sources[row]
    }

}

public class KeySelectionViewController : UIViewController, KeySelectionViewDelegate {
    
    public weak var delegate: UserConsentViewControllerDelegate?
    
    private let resolver: Resolver<PublicKeyCredentialSource>
    private let config: UserConsentUIConfig
    private let sources: [PublicKeyCredentialSource]
    
    init(
        resolver: Resolver<PublicKeyCredentialSource>,
        config: UserConsentUIConfig,
        sources: [PublicKeyCredentialSource]
    ) {
        self.resolver = resolver
        self.config = config
        self.sources = sources
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overCurrentContext
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var selectionView: KeySelectionView!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.clear
        
        self.selectionView = KeySelectionView(
            config: config,
            sources: sources
        )
        self.selectionView.delegate = self
        self.view.addSubview(self.selectionView)
        var selectionViewFrame = self.selectionView.frame
        selectionViewFrame.origin.x = (self.view.frame.width - selectionViewFrame.width) / 2.0
        selectionViewFrame.origin.y = (self.view.frame.height - selectionViewFrame.height) / 2.0
        self.selectionView.frame = selectionViewFrame
    }
    
    public func userDidCancel() {
        self.delegate?.consentViewControllerWillDismiss(viewController: self)
        dismiss(animated: true) {
            self.resolver.reject(WAKError.cancelled)
        }
    }
    
    public func userDidSelectCredential(source: PublicKeyCredentialSource) {
        self.delegate?.consentViewControllerWillDismiss(viewController: self)
        dismiss(animated: true) {
            self.resolver.fulfill(source)
        }
    }
}
