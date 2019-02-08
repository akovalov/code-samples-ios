//
//  ServerConstant.swift
//
//
//  Created by Alex Kovalov on 3/28/17.
//  Copyright © 2017 . All rights reserved.
//

import UIKit

typealias History = ServerConstant.HistoryPeriod

enum ServerConstant: String {
    
    //  MARK: BaseAuthorization
    
    case oauth = "oauth/token"
    
    
    // MARK: Currency
    
    case currencies = "currencies"
    case currencyInfo = "currencies/info/{id}"
    case prices = "prices"
    case history = "currencies/:currencyID/to/:selectedCurrency/history/:period"
    
    
    // MARK: Alerts
    
    case notifications = "notifications"
    case notificationsItem = "notifications/:id"
    
    enum ConstraintState: String {
        
        case below = "<"
        case above = ">"
    }
    
    
    // MARK: HistoryPeriod
    
    enum HistoryPeriod: String {
       
        case minute1 = "1minute"
        case minute5 = "5minute"
        case minute15 = "15minute"
        case minute30 = "30minute"
        case hour1 = "1hour"
        case hour2 = "2hour"
        case hour4 = "4hour"
        case hour6 = "6hour"
        case hour12 = "12hour"
        case day1 = "1day"
        case week1 = "1week"
        
        case day = "24h"
        case week = "7d"
        case halfOfMoth = "14d"
        case month = "30d"
        case twoMoths = "60d"
        case threeMoths = "90d"
        
        
        var title: String {
            
            switch self {
            case .day:
                return "Day"
            case .week:
                return "Week"
            case .halfOfMoth:
                return "14 days"
            case .month:
                return "Month"
            case .twoMoths:
                return "2 months"
            case .threeMoths:
                return "3 months"
            default:
                return ""
            }
        }
        
        static let capPeriods: [(History, String)] = [
            (.day, "Day"),
            (.week, "Week"),
            (.halfOfMoth, "14 days"),
            (.month, "Month"),
            (.twoMoths, "2 months"),
            (.threeMoths, "3 months")
        ]
        
        static let periods: [(History, String)] = [
            (.minute1, "1min"),
            (.minute5, "5min"),
            (.minute15, "15min"),
            (.minute30, "30min"),
            (.hour1, "1h"),
            (.hour2, "2h"),
            (.hour4, "4h"),
            (.hour6, "6h"),
            (.hour12, "12h"),
            (.day1, "1d"),
            (.week1, "1w")
        ]
    }
    
    struct Auth {
        
        static let clientId = "1002470e440e4581c0bfa2e055c5b4b2"
        static let clientSecret = "5a8e85cf4b81b43fad0476563ecac821"
        static let grantType = "client_credentials"
    }
    
    static let baseUrl = ""
    static let serverAPIUrl = baseUrl + "api/"
}
