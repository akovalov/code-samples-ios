//
//  NotificationsManager.swift
//
//
//  Created by Alex Kovalov on 2/27/18.
//  Copyright © 2018 . All rights reserved.
//

import UIKit

import Alamofire
import ObjectMapper

class NotificationsManager: ObjectManager {

    static let shared = NotificationsManager()
    
    func loadAlerts(completion: @escaping (Error?, [Alert]?) -> ()) {
        
        guard let token = RemoteNotificationsManager.shared.deviceToken else {
            return completion(NSError.appError(withDescription: "Can not get remote notifications token"), [])
        }
        
        let params: Parameters = [
            "device_id": token
        ]
        
        request(.get, serverConstant: .notifications, parameters: params, encoding: URLEncoding.default).responseJSON { (response) in
            
            var alerts: [Alert]?
            
            if let jsarray = response.JSON()?["result"] as? JSONArray {
                alerts = Mapper<Alert>().mapArray(JSONArray: jsarray)
            }
            
            completion(response.error, alerts)
        }
    }
    
    func createAlert(_ alert: Alert, completion: @escaping (Error?) -> ()) {
        
        var params: Parameters = alert.toJSON()
        params.removeValue(forKey: "id")
        
        request(.post, serverConstant: .notifications, parameters: params).responseJSON { (response) in
            
            completion(response.error)
        }
    }
    
    func removeAlert(_ alert: Alert, completion: @escaping (Error?) -> ()) {
        
        let urlParams = ["id": "\(alert.id)"]
        
        request(.delete, serverConstant: .notificationsItem, urlParameters: urlParams).responseJSON { (response) in
            
            completion(response.error)
        }
    }
    
    func updateAlert(_ alert: Alert, completion: @escaping (Error?) -> ()) {
        
        var params: Parameters = alert.toJSON()
        params.removeValue(forKey: "id")
        
        let urlParams = ["id": "\(alert.id)"]
        
        request(.put, serverConstant: .notificationsItem, parameters: params, urlParameters: urlParams).responseJSON { (response) in
            
            completion(response.error)
        }
    }
}
