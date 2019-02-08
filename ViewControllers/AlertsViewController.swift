//
//  AlertsViewController.swift
//
//
//  Created by Alex Kovalov on 2/27/18.
//  Copyright © 2018 . All rights reserved.
//

import UIKit

import RealmSwift
import MBProgressHUD
import SwipeCellKit

class AlertsViewController: BaseViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var statusLabel: UILabel!
    
    
    // MARK: Properties
    
    private var notificationToken: NotificationToken?
    private var alerts: Results<Alert> = DatabaseManager.shared.objects().sorted(byKeyPath: "id")
    
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.addSubview(refreshControl)
        
        addNotificationToken()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loadAlerts()
    }
    
    
    // MARK: Actions
    
    func refreshAlerts() {
        
        loadAlerts()
    }
    
    private func removeItem(at indexPath: IndexPath) {
        
        removeAlert(alerts[indexPath.row])
    }
    
    private func addNotificationToken() {
        
        notificationToken?.invalidate()
        notificationToken = alerts.observe { [weak self] (changes: RealmCollectionChange) in
            self?.tableView.updateWithRealmCollectionChanges(changes)
        }
    }
    
    @objc override func handleRefresh(_ refreshControl: UIRefreshControl) {
        
        loadAlerts()
    }
    
    func handleAlertChange(_ alert: Alert, toActive: Bool) {
        
        if toActive {
            
            let alertToSend = Alert(value: alert)
            
            let hud = MBProgressHUD.showAdded(to: view, animated: true)
            NotificationsManager.shared.createAlert(alertToSend) { (error) in
                hud.hide(animated: true)
                
                guard error == nil else {
                    return AlertsManager.showErrorWithAlert(error: error as NSError?)
                }
                
                DatabaseManager.shared.delete(alert)
                
                self.loadAlerts()
            }
        }
        else {
            let hud = MBProgressHUD.showAdded(to: view, animated: true)
            NotificationsManager.shared.removeAlert(alert) { (error) in
                hud.hide(animated: true)
                
                guard error == nil else {
                    return AlertsManager.showErrorWithAlert(error: error as NSError?)
                }
                
                DatabaseManager.shared.change {
                    alert.active = toActive
                }
            }
        }
    }
}


// MARK: UITableViewDataSource, UITableViewDelegate

extension AlertsViewController: UITableViewDataSource, UITableViewDelegate, SwipeTableViewCellDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        statusLabel.isHidden = !alerts.isEmpty
        
        return alerts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: AlertTableViewCell = tableView.cell()
        cell.delegate = self
        cell.alert = alerts[indexPath.row]
        cell.onActiveChanged = { [unowned self] alert, active in
            self.handleAlertChange(alert, toActive: active)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let vc: AlertViewController = UIStoryboard.viewController(fromStoryboard: .alerts)
        vc.alert = alerts[indexPath.row]
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        
        guard orientation == .right else { return nil }
        
        let delete = SwipeAction(style: .clear, title: nil) { [unowned self] (action, path) in
            self.removeItem(at: path)
        }
        
        delete.image = #imageLiteral(resourceName: "delete")
        
        return [delete]
    }
}


// MARK: API

extension AlertsViewController {
    
    private func loadAlerts() {
        
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        NotificationsManager.shared.loadAlerts { (error, alerts) in
            hud.hide(animated: true)
            
            self.refreshControl.endRefreshing()
            
            guard error == nil else { return }
            
            if alerts != nil {
                DatabaseManager.shared.addArray(alerts!)
                
                let alertIdsFromServer = alerts!.compactMap({ $0.id })
                let alertsInDbToDelete = self.alerts.filter("NOT (id IN %@)", alertIdsFromServer)
                if alertsInDbToDelete.count > 0 {
                    
                    DatabaseManager.shared.change {
                        
                        alertsInDbToDelete.forEach({ (alert) in
                            alert.active = false
                        })
                    }
                }
            }
        }
    }
    
    private func removeAlert(_ alert: Alert) {
        
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        NotificationsManager.shared.removeAlert(alert) { (error) in
            hud.hide(animated: true)
            
            guard error == nil else { return }
            
            DatabaseManager.shared.delete(alert)
        }
    }
}
