//
//  UpdateManager.swift
//
//
//  Created by Alex Kovalov on 2/23/18.
//  Copyright © 2018 . All rights reserved.
//

import Foundation

import RealmSwift

class UpdateManager {
    
    static let idsLeftToUpdateChangedNotificationName = Notification.Name(rawValue: "idsLeftToUpdateChangedNotificationName")
    
    static let shared = UpdateManager()
    
    
    // MARK: - Properties
    
    var idsLeftToUpdateCount: Int {
        return idsLeftToUpdate.count
    }
    
    private let operationQueue = OperationQueue()
    private let maxIdsCharsInRequestCount = 300
    
    private var idsLeftToUpdate: [String] = [] {
        didSet {
            NotificationCenter.default.post(Notification(name: UpdateManager.idsLeftToUpdateChangedNotificationName))
        }
    }
    private var showedCurrenciesCount: Int = 0
    private var startUpdateCurrenciesCount: Int = 0
    
    private var currenciesLastUpdateDate: Date {
        get { return Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: "currenciesLastUpdateDate")) }
        set { UserDefaults.standard.set(newValue.timeIntervalSince1970, forKey: "currenciesLastUpdateDate") }
    }
    private var pricesLastUpdateDate: Date = Date(timeIntervalSince1970: 0)
    
    
    // MARK: - Currency
    
    func updateCurrencies(completion: @escaping (_ error: NSError?) -> Void) {
        
        guard Date().timeIntervalSince(currenciesLastUpdateDate) > 86400 else { // once in a day
            return completion(nil)
        }
        
        CurrencyManager.shared.getCurrencies { (error, objs) in
            
            guard error == nil else {
                return completion(error)
            }
            
            if let objs = objs {
                
                let alreadySavedIds: [String] = CurrencyManager.shared.currencies.value(forKeyPath: "@distinctUnionOfObjects.id") as! [String]
                let newObjs = objs.filter({ !alreadySavedIds.contains($0.id) })
                
                DatabaseManager.shared.addArray(newObjs)
                
                if objs.count > 0 {
                    self.currenciesLastUpdateDate = Date()
                }
            }
            
            completion(nil)
        }
    }
    
    
    // MARK: - Price
    
    func updatePrices(withShowedCurrencies: Results<Currency>, completion: @escaping ((_ error: NSError?) -> Void)) {
        
        guard Date().timeIntervalSince(pricesLastUpdateDate) > 30 || !priceWasRequestedForAllCurrencies() else { // once in 30s
            return completion(nil)
        }
        
        guard idsLeftToUpdate.count == 0 || (idsLeftToUpdate.count > 0 && Date().timeIntervalSince(pricesLastUpdateDate) > 300) else { // if not finished update in 5 min allow to update again
            return completion(nil)
        }
        
        pricesLastUpdateDate = Date()
        
        DispatchQueue.main.async {
            
            self.showedCurrenciesCount = withShowedCurrencies.count
            
            let ids = self.currenciesIdsNeedsToBeUpdated(withShowedCurrencies: withShowedCurrencies)
            self.idsLeftToUpdate = ids
            
            self.startUpdateCurrenciesCount = self.idsLeftToUpdate.count
            
            self.addOperation {
                self.loadNextPrices(completion: completion)
            }
        }
    }
    
    private func loadNextPrices(completion: @escaping ((_ error: NSError?) -> Void)) {
        
        guard !idsLeftToUpdate.isEmpty else {
            
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        var idsInRequestCount = 0
        var idsQuery = ""
        
        for id in idsLeftToUpdate {
            let newIdsQuery = idsQuery + (idsQuery.isEmpty ? "" : ",") + id
            guard newIdsQuery.count < maxIdsCharsInRequestCount else { break }
            idsQuery = newIdsQuery
            idsInRequestCount += 1
        }
        
        idsLeftToUpdate = idsLeftToUpdate.count > idsInRequestCount ? Array(idsLeftToUpdate[idsInRequestCount...(idsLeftToUpdate.count - 1)]) : []
        
        CurrencyManager.shared.getPrices(forIDs: idsQuery) { error, prices in
        
            guard error == nil else {
                return completion(error)
            }
            
            NotificationCenter.default.post(name: Constant.Notifications.updateManagerDidUpdatePrice.name, object: prices)
            self.loadNextPrices(completion: completion)
        }
    }
    
    func priceWasRequestedForAllCurrencies() -> Bool {
        
        if DatabaseManager.shared.objects(Currency.self).isEmpty {
            
            return false
        }
        
        let currenciesWithNotRequestedPrice = DatabaseManager.shared.objects(Currency.self).filter("priceRequested == false")
        
        return currenciesWithNotRequestedPrice.count == 0
    }
    
    
    // MARK: - Operation
    
    private func addOperation(_ block: @escaping () -> ()) {
        
        stopOperations()
        operationQueue.addOperation(block)
        
        NotificationCenter.default.post(Constant.Notifications.updateManagerStartUpdatingPrice)
    }
    
    private func stopOperations() {
        
        operationQueue.cancelAllOperations()
    }
    
    
    // MARK: - Ids
    
    func currenciesIdsNeedsToBeUpdated(withShowedCurrencies: Results<Currency>) -> [String] {
        
        let firstIds: [String] = withShowedCurrencies.compactMap({ $0.id })
        let allIds = DatabaseManager.shared.objects(Currency.self)
            .filter("priceToUSD != nil")
            .filter("NOT id IN %@", firstIds)
            .compactMap({ $0.id })
        
        let toUpdate = firstIds + allIds
        return toUpdate
    }
}
