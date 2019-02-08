//
//  PostManager.swift
//
//
//  Created by Alex Kovalov on 12/21/17.
//  Copyright © 2017 . All rights reserved.
//

import Foundation
import UIKit

class PostManager: ObjectManager {
    
    static let shared = PostManager()
    
    // MARK: - Properties
    
    // MARK: - Lifecycle
    
    // MARK: - Actions
    
    open func getPostsForUser(_ user: User, completion: @escaping (_ objs: [Post]?, _ error: NSError?) -> Void) {
        
        let urlParams = [
            "id": "\(user.id)"
        ]
        request(method: .get, serverAPI: .userByIdPosts, parameters: nil, urlParameters: urlParams).responseJSON { (response) in
            
            let objs: [Post]? = response.resultArray()
            completion(objs, response.error())
        }
    }
}
