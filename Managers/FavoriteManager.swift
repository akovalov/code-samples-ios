//
//  FavoriteManager.swift
//
//
//  Created by Alex Kovalov on 2/22/18.
//  Copyright © 2018 . All rights reserved.
//

import UIKit

import RealmSwift

class FavoriteManager {
    
    // MARK: Properties
    
    private static let kFavoriteObjects = "FavoriteObjects"
    
    public static var ids: [String] {
        set {
            UserDefaults.standard.set(newValue, forKey: kFavoriteObjects)
        }
        get {
           return UserDefaults.standard.array(forKey: kFavoriteObjects) as? [String] ?? []
        }
    }
    public static var objects: Results<Currency> {
        return getObjects()
    }
    
    
    // MARK: Actions
    
    private static func getObjects() -> Results<Currency> {
        return DatabaseManager.shared.objects().filter("id IN %@", ids)
    }
    
    public static func addCurrency(toTheFavorite currency: Currency) {
    
        ids.append(currency.id)
    }
    
    public static func removeCurrency(fromTheFavorite currency: Currency) {
        
        if let index = ids.index(of: currency.id) {
            
            ids.remove(at: index)
        }
    }
}
