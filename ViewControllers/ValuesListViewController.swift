//
//  ValuesListViewController.swift
//
//
//  Created by Alex Kovalov on 5/30/17.
//  Copyright © 2017 . All rights reserved.
//

import Foundation
import UIKit

class ValuesListViewController: BaseTableViewController {
    
    // MARK: Properties
    
    var values: [String] = []
    var selectedValue: String?
    var selectedValueHandler: ((String, Int) -> Void)!
    var getValuesHandler: ((ValuesListViewController) -> Void)?
    var hideSearchBar: Bool = false
    
    fileprivate var searchResults: [String]?
    
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        
        if hideSearchBar {
            
            if let headerViewFrame = tableView.tableHeaderView?.frame {
                tableView.tableHeaderView?.frame = headerViewFrame.withSizeHeight(headerViewFrame.size.height - searchBar.frame.size.height)
            }
            searchBar.removeFromSuperview()
            searchBar = nil
        }
        
        super.viewDidLoad()
        
        getValuesHandler?(self)
    }
    
    
    // MARK: Actions
    
    override func filterListBy(searchText: String?) {
        
        searchResults = nil
        if let text = searchText, !text.isEmpty {
            searchResults = values.filter({ $0.localizedCaseInsensitiveContains(text) })
        }
        
        tableView.reloadData()
    }
}



// MARK: UITableViewDelegate & UITAbleViewDataSource

extension ValuesListViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults?.count ?? values.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let value = searchResults?[indexPath.row] ?? values[indexPath.row]
        
        let cell: ValueTableViewCell = tableView.cell()
        cell.leftValueLabel.text = value
        cell.selectedMarkImageView.isHidden = selectedValue != value
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedValue = searchResults?[indexPath.row] ?? values[indexPath.row]
        let selectedIndex = values.index(of: selectedValue) ?? 0
        
        selectedValueHandler(selectedValue, selectedIndex)
        
        navigationController?.popViewController(animated: true)
    }
}

