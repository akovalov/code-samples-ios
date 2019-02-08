//
//  Alert.swift
//
//
//  Created by Alex Kovalov on 2/27/18.
//  Copyright © 2018 . All rights reserved.
//

import Foundation

import ObjectMapper
import RealmSwift

class Alert: Object, Mappable {
    
    // MARK: Properties
    
    @objc dynamic var id: Int = 0
    @objc dynamic var deviceId: String?
    @objc dynamic var currency: String?
    @objc dynamic var constraint: String?
    @objc dynamic var toCurrency: String = SettingsManager.shared.toCurrency.rawValue
    @objc dynamic var exchange: String?
    @objc dynamic var value: String?
    @objc dynamic var active: Bool = true
    @objc dynamic var createdAt: Date?
    
    
    // MARK: Lifecycle
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    
    // MARK: Mappable
    
    required convenience public init?(map: Map) {
        self.init()
    }
    
    public func mapping(map: Map) {
        
        id <- map["id"]
        deviceId <- map["device_id"]
        currency <- map["currency"]
        constraint <- map["constraint"]
        exchange <- map["exchange"]
        toCurrency <- map["toCurrency"]
        value <- map["value"]
        createdAt <-  (map["createdAt"], ISO8601ExtendedDateTransform())
    }
}


// MARK: Helper

extension Alert {
    
    var currencyObject: Currency? {
     
        return DatabaseManager.shared.objectForPrimaryKey(key: "id", value: currency)
    }
}
