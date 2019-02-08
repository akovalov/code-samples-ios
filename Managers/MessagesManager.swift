//
//  MessagesManager.swift
//
//
//  Created by Alex Kovalov on 5/13/17.
//  Copyright © 2017 . All rights reserved.
//

import Foundation
import UIKit

import ObjectMapper
import Alamofire

public class MessagesManager: ObjectManager {
    
    public static let shared = MessagesManager()
    
    
    // MARK: Properties
    
    // MARK: Lifecycle
    
    // MARK: Actions
    
    func getDialogues(page: Int, limit: Int, completion: @escaping (_ dialogues: [Dialogue]?, _ error: NSError?) -> Void) {
        
        let params: Parameters = [
            "page": page,
            "limit": limit
        ]
        
        request(method: .get, serverAPI: .messagesDialogues, parameters: params, encoding: URLEncoding.default).responseJSON { response in
            
            let objs: [Dialogue]? = response.resultArray()
            completion(objs, response.error())
        }
    }
    
    func newDialogue(withUserId userId: Int, completion: @escaping (_ dialogue: Dialogue?, _ error: NSError?) -> Void) {
        
        let urlParams = [
            "id": "\(userId)"
        ]
        request(method: .get, serverAPI: .messagesNewDialogue, urlParameters: urlParams).responseJSON { response in
            
            let obj: Dialogue? = response.resultObject()
            completion(obj, response.error())
        }
    }
    
    func getMessages(inDialogueWithId dialogueId: Int, page: Int, completion: @escaping (_ dialogue: Dialogue?, _ messages: [Message]?, _ error: NSError?) -> Void) {
        
        let urlParams = [
            "id": "\(dialogueId)"
        ]
        let params = [
            "page": "\(page)",
        ]
        
        request(method: .get, serverAPI: .messagesInDialogue, parameters: params, urlParameters: urlParams, encoding: URLEncoding.default).responseJSON { response in
            
            var dialogue: Dialogue?
            var messages: [Message]?
            
            if let dialogueJSON = response.JSON()?["group"] as? [String: Any] {
                dialogue = Mapper<Dialogue>().map(JSON: dialogueJSON)
            }
            if let messagesJSON = response.JSON()?["messages"] as? [[String: Any]] {
                messages = Mapper<Message>().mapArray(JSONArray: messagesJSON)
            }
            
            completion(dialogue, messages, response.error())
        }
    }
    
    func sendMessage(content: String, toDialogueWithId dialogueId: Int, completion: @escaping (_ message: Message?, _ error: NSError?) -> Void) {
        
        let urlParams = [
            "id": "\(dialogueId)"
        ]
        let params = [
            "content": content
        ]
        request(method: .post, serverAPI: .messageSend, parameters: params, urlParameters: urlParams).responseJSON(completionHandler: { response in
            
            var message: Message?
            if let messageJSON = response.JSON()?["message"] as? [String: Any] {
                message = Mapper<Message>().map(JSON: messageJSON)
            }
            
            completion(message, response.error())
        })
    }
    
    func deleteMessage(withId messageId: Int, inDialogueWithId dialogueId: Int, completion: @escaping (_ error: NSError?) -> Void) {
        
        let urlParams = [
            "id": "\(dialogueId)",
            "message_id": "\(messageId)"
        ]
        
        request(method: .delete, serverAPI: .messageDelete, urlParameters: urlParams).responseString(completionHandler: { response in
            
            completion(response.error())
        })
    }
}


// MARK: Push Notifications

extension MessagesManager {
    
    func handlePush(push: Push, appOpenedFromPush: Bool) {
        
        guard push.type == PushType.message.rawValue else { return }
        
        if appOpenedFromPush {
            openDialogueForPush(push: push)
        }
        else {
            
            NotificationBanner.show(title: "Новое сообщение", subtitle: push.alert?.withDecodedEmoji() ?? "", image: #imageLiteral(resourceName: "MessagesIcon"), didTapBlock: {
                self.openDialogueForPush(push: push)
            })
        }
    }
    
    func openDialogueForPush(push: Push) {
        
        guard UserManager.shared.sessionActive else { return }
        guard let dialogueJSON = push.data else { return }
        guard let dialogueId = dialogueJSON["group_id"] as? Int else { return }
        
        let topVC = RootNavigationController.shared.topViewController
        
        if topVC is DialoguesViewController {
            return (topVC as! DialoguesViewController).openDialogue(withId: dialogueId)
        }
        else if topVC is MessagesViewController {
            
            if (topVC as! MessagesViewController).dialogue.id == dialogueId { return }
            
            topVC?.navigationController?.popViewController(animated: false)
            (RootNavigationController.shared.topViewController as? DialoguesViewController)?.openDialogue(withId: dialogueId)
        }
        else {
            
            RootNavigationController.shared.popToRootViewController(animated: false)
            
            let vc: DialoguesViewController = UIStoryboard.instantiateViewControllerFromStoryboardOfType(.messages)
            RootNavigationController.shared.pushViewController(vc, animated: true)
            vc.openDialogue(withId: dialogueId)
        }
    }
}
