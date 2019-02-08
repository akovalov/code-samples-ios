//
//  UserFriendsViewController.swift
//
//
//  Created by Alex Kovalov on 6/18/17.
//  Copyright © 2017 . All rights reserved.
//

import Foundation
import UIKit

class UserFriendsViewController: BaseTableViewController {
    
    // MARK: Properties
    
    var user: User!
    var friends: [User] = []
    
    fileprivate var searchResults: [User]?
    
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = user.displayCompositeName
        getFriends()
    }
    
    
    // MARK: Actions
    
    func getFriends() {
        
        UserManager.shared.getFriendsOfUser(withId: user.id) { (error, friends) in
            
            guard error == nil else {
                return AlertsManager.showErrorWithAlert(error: error)
            }
            
            self.friends = friends ?? []
            
            self.tableView.reloadData()
        }
    }
    
    override func filterListBy(searchText: String?) {
        
        searchResults = nil
        if searchText?.isEmpty == false {
            searchResults = friends.filter({ $0.firstName?.contains(searchText!) == true || $0.lastName?.contains(searchText!) == true || $0.fullName?.contains(searchText!) == true })
        }
        
        tableView.reloadData()
    }
}


// MARK: UITableViewDelegate & UITAbleViewDataSource

extension UserFriendsViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return searchResults?.count ?? friends.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 50
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UserTableViewCell.self), for: indexPath) as! UserTableViewCell
        cell.user = searchResults?[indexPath.row] ?? friends[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let vc: UserViewController = UIStoryboard.instantiateViewControllerFromStoryboardOfType(.user)
        vc.user = searchResults?[indexPath.row] ?? friends[indexPath.row]
        navigationController?.pushViewController(vc, animated: true)
    }
}
