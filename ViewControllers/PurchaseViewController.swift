//
//  PurchaseViewController.swift
//
//
//  Created by Alex Kovalov on 11/14/18.
//  Copyright © 2018 . All rights reserved.
//

import UIKit
import SVProgressHUD

class PurchaseViewController: BaseViewController {

    
    // MARK: - Properties
    
    @IBOutlet weak var pushaseButton: UIButton!
    @IBOutlet weak var descritionLabel: UILabel!
    @IBOutlet weak var descrTextView: UITextView!
    @IBOutlet weak var agreeToTermsTextView: UITextView!
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let isPaid = App.userSession.currentUser?.isPaid ?? false
        pushaseButton.isHidden = isPaid
        
        agreeToTermsTextView.isHidden = isPaid
        setupAgreeTerms()
        
        getProductInfo()
    }
    
    
    // MARK: - Setup
    
    func setupAgreeTerms() {
        
        let agreeText = R.string.profile.byUpgradingIAgreeToThe() + R.string.profile.privacyPolicyTermsConditions()
        let attrStr = NSMutableAttributedString(string: agreeText, attributes: [
            .foregroundColor: #colorLiteral(red: 0.5176470588, green: 0.6, blue: 0.7921568627, alpha: 1)
            ])
        
        let linkRange = (attrStr.string as NSString).range(of: R.string.profile.privacyPolicyTermsConditions())
        attrStr.addAttribute(.link, value: Link.privacy, range: linkRange)
        
        agreeToTermsTextView.attributedText = attrStr
        
        agreeToTermsTextView.linkTextAttributes = [
            .foregroundColor: #colorLiteral(red: 0.2745098039, green: 0.6980392157, blue: 0.6039215686, alpha: 1)
        ]
        agreeToTermsTextView.delegate = self
    }
    
    
    // MARK: - Actions
    
    func getProductInfo() {
        
        guard let productId = ProductManager.shared.productIdSubscriptions.first else {
            return
        }
        
        if let price = ProductManager.shared.getPrice(for: productId) {
            
            pushaseButton.setTitle(R.string.profile.upgradeNow(price), for: .normal)
            descritionLabel.text = R.string.profile.purchaseDescription(price)
            descrTextView.text = R.string.profile.purchaseDescriptionLong(price)
        } else {
            
            Loader.show()
            ProductManager.shared.getProductInfo(productId) { [weak self] error, product in
                Loader.hide()
                guard error == nil else {
                    return
                }
                
                let price = product?.localizedPrice ?? ""
                ProductManager.shared.setPrice(for: productId, price)
                self?.pushaseButton.setTitle(R.string.profile.upgradeNow(price), for: .normal)
                self?.descritionLabel.text = R.string.profile.purchaseDescription(price)
                self?.descrTextView.text = R.string.profile.purchaseDescriptionLong(price)
            }
        }
    }
    
    
    // MARK: - IBActions
    
    @IBAction func upgradeNow(_ sender: Any) {
    
        guard let productId = ProductManager.shared.productIdSubscriptions.first else {
            return
        }

        SVProgressHUD.show()

        ProductManager.shared.purchaseProduct(productId) { error, _, transactionId in

            guard error == nil else {

                SVProgressHUD.dismiss()
                return AlertsManager.showErrorWithApiError(error: error)
            }

            ProductManager.shared.fetchReceipt(transactionId) { [weak self] error in

                SVProgressHUD.dismiss()

                guard error == nil else {
                    return AlertsManager.showErrorWithApiError(error: error)
                }

                NotificationCenter.default.post(Notification(name: .shouldUpdateSongs, object: nil, userInfo: nil))
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
}


// MARK: - UITextViewDelegate

extension PurchaseViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        if UIApplication.shared.canOpenURL(URL) {
            App.navigator.open(url: URL, from: self)
            return false
        }
        return true
    }
}
