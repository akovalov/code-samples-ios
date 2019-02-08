//
//  ObjectManager.swift
//
//
//  Created by Alex Kovalov on 3/20/17.
//  Copyright © 2017 . All rights reserved.
//

import Foundation

import Alamofire
import AlamofireNetworkActivityIndicator
import ObjectMapper
import HTTPStatusCodes

typealias JSON = [String: Any]
typealias JSONArray = [[String: Any]]

class ObjectManager {
    
    func headers() -> HTTPHeaders {
        
        var headers: HTTPHeaders = [:]
        if let token = Token.token, let type = token.tokenType, let str = token.accessToken {
            headers["Authorization"] = type + " " + str
        }
        
        return headers
    }
    
    func request(_ method: HTTPMethod,
                 serverConstant: ServerConstant,
                 parameters: Parameters? = nil,
                 urlParameters: [String: String]? = nil,
                 encoding: ParameterEncoding = URLEncoding.httpBody,
                 cachePolicy: URLRequest.CachePolicy? = nil
        ) -> DataRequest {
        
        let urlString = serverConstant != .oauth ? ServerConstant.serverAPIUrl + serverConstant.rawValue : ServerConstant.baseUrl + serverConstant.rawValue
        
        let url = urlString.replacingURLParameters(urlParameters: urlParameters)
        
        var request: DataRequest?
        
        if let cachePolicy = cachePolicy {
            
            if var originalRequest = try? URLRequest(url: url, method: method, headers: headers()) {
                
                originalRequest.cachePolicy = cachePolicy
                
                if let encodedURLRequest = try? encoding.encode(originalRequest, with: parameters) {
                    request = Alamofire.request(encodedURLRequest)
                }
            }
        }
        
        if request == nil {
            request = Alamofire.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers())
        }
        
        return request!
            .validate({ (urlRequest, urlResponse, data) -> Request.ValidationResult in
                return self.validate(urlRequest: urlRequest, httpUrlResponce: urlResponse, data: data)
            })
    }
}



// MARK: Validation

extension ObjectManager {
    
    func validate(urlRequest: URLRequest?, httpUrlResponce: HTTPURLResponse, data: Data?) -> Request.ValidationResult {
        
        if httpUrlResponce.statusCode == HTTPStatusCode.unauthorized.rawValue || httpUrlResponce.statusCode == 503 {
            
            OAuthManager.shared.getToken({ (_, _) in })
            return Request.ValidationResult.failure(NSError.refreshTokenError())
        }
        else if Array(200..<300).contains(httpUrlResponce.statusCode) {
            return Request.ValidationResult.success
        }
        else {
            let reason: AFError.ResponseValidationFailureReason = .unacceptableStatusCode(code: httpUrlResponce.statusCode)
            return .failure(AFError.responseValidationFailed(reason: reason))
        }
    }
}
