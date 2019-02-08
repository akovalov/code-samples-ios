//
//  Constant.swift
//  
//
//  Created by Alex Kovalov on 1/26/18.
//  Copyright © 2018 Requestum. All rights reserved.
//

import UIKit

struct Constant {
    static let debugging = true
    
    struct APIKeys {
        static let YoutubeAPI = "AIzaSyCIiFp7qAEWyItUV3OfhoQkxEeIln3I_yY"
    }
    struct Notifications {
        static let updateManagerStartUpdatingPrice = Notification(name: Notification.Name(rawValue: "updateManagerStartUpdatingPrice"))
        static let updateManagerDidUpdatePrice = Notification(name: Notification.Name(rawValue: "updateManagerDidFinishUpdatingPrice"))
    }
    
    struct Font {
        
        static let regular = UIFont(name: "Montserrat-Regular", size: 17)!
        static let medium = UIFont(name: "Montserrat-Medium", size: 17)!
    }
    
    struct Color {

        static let gradientColors = [#colorLiteral(red: 0.4156862745, green: 0.462745098, blue: 0.6156862745, alpha: 1), #colorLiteral(red: 0.3137254902, green: 0.368627451, blue: 0.5411764706, alpha: 1)]
        static let red = #colorLiteral(red: 0.9411764706, green: 0.3568627451, blue: 0.4666666667, alpha: 1)
        static let green = #colorLiteral(red: 0.3568627451, green: 0.9411764706, blue: 0.5803921569, alpha: 1)
        static let linesColor = #colorLiteral(red: 0.537254902, green: 0.5843137255, blue: 0.7529411765, alpha: 1)
        static let chartLabelsColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)
    }
    
    static let gradient: Gradient = Gradient(colors: Color.gradientColors, startPoint: CGPoint(x: 0, y: 0.75), endPoint: CGPoint(x: 1, y: 0.2), cornerRadius: 6)
    static let blueGradient: Gradient = Gradient(colors: [#colorLiteral(red: 0, green: 0.9490196078, blue: 0.9960784314, alpha: 1), #colorLiteral(red: 0.3098039216, green: 0.6745098039, blue: 0.9960784314, alpha: 1)], startPoint: CGPoint(x: 0, y: 0.5), endPoint: CGPoint(x: 1, y: 0.5), cornerRadius: 6)
}

struct Gradient {
    
    var colors: [UIColor] = []
    var startPoint: CGPoint = .zero
    var endPoint: CGPoint = .zero
    var cornerRadius: CGFloat? = nil
}


// MARK: - ToCurrency

enum ToCurrency: String {
    
    case dollar = "USD"
    case pounds = "GBP"
    case euro = "EUR"
    
    case btc = "BTC"
    case eth = "ETH"
    
    var badge: String {
        switch self {
        case .dollar: return "$"
        case .pounds: return "£"
        case .euro: return "€"
            
        case .btc: return "Ƀ"
        case .eth: return "Ξ"
        }
    }
    
    static func all() -> [ToCurrency] {
        
        return [ .dollar, .pounds, .euro, .btc, .eth ]
    }
    
    static func allTickersString() -> String {
        
        return all().map({ $0.rawValue }).joined(separator: ",")
    }
}
