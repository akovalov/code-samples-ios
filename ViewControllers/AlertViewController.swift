//
//  AlertViewController.swift
//
//
//  Created by Alex Kovalov on 2/27/18.
//  Copyright © 2018 . All rights reserved.
//

import UIKit

import MBProgressHUD

class AlertViewController: BaseViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var controlsView: AlertControlsView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var currencyImageView: UIImageView!
    @IBOutlet weak var currencyNameLabel: UILabel!
    @IBOutlet weak var priceTextField: UITextField!
    @IBOutlet weak var toCurrencyLabel: UILabel!
    
    
    // MARK: Properties
    
    var alert: Alert?
    
    private var currency: Currency?
    private var constraintState: ServerConstant.ConstraintState?
    private var toCurrency: ToCurrency = .dollar
    
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addEndEditingGesture()
        setupControlsView()
        showData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !saveButton.hasGradient() {
            setupSaveButton()
        }
        controlsView.layoutIfNeeded()
    }
    
    
    // MARK: IBActions
    
    @IBAction func selectCurrency() {
        
        let vc: AlertCurrenciesViewController = UIStoryboard.viewController(fromStoryboard: .alerts)
        vc.modalPresentationStyle = .overCurrentContext
        vc.delegate = self
        vc.selectedCurrency = currency
        TabBarController.shared.present(vc, animated: false) {
            vc.searchTextField.becomeFirstResponder()
        }
    }
    
    @IBAction func savePressed() {
        
        guard currency != nil else { return AlertsManager.showErrorWithAlert(error: NSError.appError(withDescription: "Please select a currency")) }
        
        guard constraintState != nil else { return AlertsManager.showErrorWithAlert(error: NSError.appError(withDescription: "Please select range")) }
        
        guard let priceText = priceTextField.text, !priceText.isEmpty else {
            return AlertsManager.showErrorWithAlert(error: NSError.appError(withDescription: "Please enter the price"))
        }
        
        guard let deviceToken = RemoteNotificationsManager.shared.deviceToken else {
            return registerForRemoteNotifications()
        }
        
        let alert = Alert()
        alert.deviceId = deviceToken
        alert.currency = currency?.id
        alert.value = priceText
        alert.constraint = constraintState?.rawValue
        alert.toCurrency = toCurrency.rawValue
        
        if let alertId = self.alert?.id, self.alert?.active == true {
            alert.id = alertId
            updateAlert(alert)
        }
        else if let originalAlert = self.alert, originalAlert.id != nil, !originalAlert.active {
            
            DatabaseManager.shared.delete(originalAlert)
            
            createAlert(alert)
        }
        else {
            
            createAlert(alert)
        }
    }
    
    @IBAction func chooseToCurrency(_ sender: UIButton) {
        
        showCurrencyPicker()
    }
    
    
    // MARK: Actions
    
    private func setupControlsView() {
        
        controlsView.state = ServerConstant.ConstraintState(rawValue: alert?.constraint ?? "")
        controlsView.completion = { [unowned self] constraintState in
            self.constraintState = constraintState
        }
    }
    
    private func setupSaveButton() {
        
        saveButton.addGradient(Constant.blueGradient)
    }
    
    private func updateView(withCurrency currency: Currency) {
        
        currencyNameLabel.text = currency.name
        currencyImageView.image = nil
        if let str = currency.logoUrl {
            currencyImageView.sd_setImage(with: URL(string: str), completed: nil)
        }
        priceTextField.text = nil
        priceTextField.placeholder = nil
        if let price = currency.priceToCurrency(toCurrency)?.price {
            priceTextField.placeholder = String(format: "%.2f", price)
        }
        
        toCurrencyLabel.text = toCurrency.rawValue
        
        self.currency = currency
    }
    
    private func showData() {
        
        guard alert != nil else { return }
        
        priceTextField.text = alert?.value
        currencyNameLabel.text = alert?.currencyObject?.name
        
        currencyImageView.image = nil
        if let str = alert?.currencyObject?.logoUrl {
            currencyImageView.sd_setImage(with: URL(string: str), completed: nil)
        }
        
        currency = alert?.currencyObject
        constraintState = ServerConstant.ConstraintState(rawValue: alert?.constraint ?? "")
        toCurrency = ToCurrency(rawValue: alert?.toCurrency ?? "") ?? .dollar
    }
    
    private func registerForRemoteNotifications() {
        
        RemoteNotificationsManager.shared.registerForRemoteNotifications(authorizationCompletion: { authorized in
            
            guard authorized else {
                return AlertsManager.showSettingsRequired(forResourceNamed: "Notifications")
            }
            
            let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
            NotificationCenter.default.addObserver(forName: AppDidRegisterForPushNotificationsNotification, object: nil, queue: nil, using: { (_) in
                
                DispatchQueue.main.async {
                    
                    hud.hide(animated: true)
                    self.savePressed()
                }
            })
        })
    }
    
    private func showCurrencyPicker() {
        
        let vc: ToCurrenciesViewController = UIStoryboard.viewController(fromStoryboard: .dashboard)
        vc.modalPresentationStyle = .popover
        vc.preferredContentSize = CGSize(width: view.bounds.width - 32, height: 44 * CGFloat(ToCurrency.all().count))
        vc.delegate = self
        vc.selected = toCurrency
        
        let popover = vc.popoverPresentationController!
        popover.backgroundColor = Constant.Color.gradientColors.first
        popover.delegate = self
        popover.sourceView = toCurrencyLabel
        
        present(vc, animated: true)
    }
}


// MARK: UITextFieldDelegate

extension AlertViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField.text?.contains(".") == true && string == "." {
            return false
        }
        
        return "1234567890.".contains(string) || string == ""
    }
}


// MARK: AlertCurrenciesDelegate

extension AlertViewController: AlertCurrenciesDelegate {
    
    func viewController(_ viewController: AlertCurrenciesViewController, didSelectCurrency currency: Currency) {
        
        viewController.dismiss(animated: false)
        updateView(withCurrency: currency)
    }
}


// MARK: API

extension AlertViewController {
    
    private func createAlert(_ alert: Alert) {
        
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        NotificationsManager.shared.createAlert(alert) { (error) in
            hud.hide(animated: true)
            
            guard error == nil else { return AlertsManager.showErrorWithAlert(error: error as NSError?) }
            
            self.navigationController?.popViewController(animated: true)
            SuccessViewController.show(withSubtitle: "You have created a new alert.")
            
            AnalyticsManager.logEvent(.alertMade, withParams: ["currency" : alert.currency!, "exchange" : alert.exchange == nil ? "globalAverage" : alert.exchange!, "value" : alert.value!, "constraint" : alert.constraint!])
            
            RatingsManager.userDidSignificantEvent(true)
        }
    }
    
    private func updateAlert(_ alert: Alert) {
        
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        NotificationsManager.shared.updateAlert(alert) { (error) in
            hud.hide(animated: true)
            
            guard error == nil else { return AlertsManager.showErrorWithAlert(error: error as NSError?) }
            
            self.navigationController?.popViewController(animated: true)
            SuccessViewController.show(withSubtitle: "You have updated this alert.")
        }
    }
}


// MARK: - RealCurrenciesSelectorDelegate

extension AlertViewController: RealCurrenciesSelectorDelegate {
    
    func selector(_ viewController: ToCurrenciesViewController, didSelectAppCurrency currency: ToCurrency) {
        
        viewController.dismiss(animated: true)
     
        toCurrency = currency
        
        if let cryptoCurrency = self.currency {
            updateView(withCurrency: cryptoCurrency)
        }
    }
}


// MARK: - UIPopoverPresentationControllerDelegate

extension AlertViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
