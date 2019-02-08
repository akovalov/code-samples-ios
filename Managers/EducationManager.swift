//
//  EducationManager.swift
//
//
//  Created by Alex Kovalov on 3/4/18.
//  Copyright © 2018 . All rights reserved.
//

import Foundation
import UIKit

import FeedKit
import ObjectMapper

class EducationManager: NSObject {
    
    static let shared = EducationManager()
    
    // MARK: - Properties
    
    var educationLinks: [EducationLink] = []
    
    
    // MARK: - Lifecycle
    
    override init() {
        super.init()
        
        loadLinks()
    }
    
    
    // MARK: - Actions
    
    func loadLinks() {
        
        let jsonUrl = Bundle.main.url(forResource: "Education", withExtension: "json")!
        let jsonData = try! Data(contentsOf: jsonUrl)
        let json = try! JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as! [[String: Any]]
        
        educationLinks = Mapper<EducationLink>().mapArray(JSONArray: json)
    }
}
