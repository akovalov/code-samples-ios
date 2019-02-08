//
//  DatabaseManager.swift
//
//
//  Created by Alex Kovalov on 8/24/16.
//  Copyright © 2016 Requestum. All rights reserved.
//

import Foundation

import RealmSwift

let StoreFileNameDefault = "CryptoX"
let StoreFileExtension = ".realm"

class DatabaseManager: NSObject {
    
    static let shared = DatabaseManager()
    
    
    // MARK: Lifecycle
    
    init(storeName: String = StoreFileNameDefault) {
    
        var config = DatabaseManager.migrate()
        config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent(storeName + StoreFileExtension)
        Realm.Configuration.defaultConfiguration = config
        
        super.init()
    }
    
    func deleteStoreFile(storeName: String = StoreFileNameDefault) {
      
        let fileURL = storeFileURL()
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try! FileManager.default.removeItem(at: fileURL as URL)
        }
    }
    
    func storeFileURL(storeName: String = StoreFileNameDefault) -> URL {
       
        let fileURL = Realm.Configuration().fileURL!.deletingLastPathComponent().appendingPathComponent(storeName + StoreFileExtension)

        return fileURL
    }
    
    // MARK: Actions
    
    func add(_ object: Object) {
        write { (realm) in
            realm.add(object, update: true)
        }
    }
    
    func addArray(_ array: [Object]) {
        write { (realm) in
            realm.add(array, update: true)
        }
    }
    
    func addArray<T: Object>(array: List<T>) {
        
        write { (realm) in
            realm.add(array)
        }
    }
    
    func change(_ changesBlock: @escaping () -> Void) {
            
        write { (realm) in
            changesBlock()
        }
    }
    
    func delete(_ object: Object) {
        write { (realm) in
            realm.delete(object)
        }
    }
    
    func deleteObjects<T: Object>(_ objects: List<T>) {
        write { (realm) in
            realm.delete(objects)
        }
    }
    
    func deleteObjects<T: Object>(_ objects: Results<T>) {
        write { (realm) in
            realm.delete(objects)
        }
    }
    
    fileprivate func write(_ changes: (Realm) -> Void) {
        
        let realm = try! Realm()
        do {
            try realm.safeWrite {
                changes(realm)
            }
        }
        catch (let error as NSError) {
            NSLog(error.description)
        }
    }
    
    func objects<T: Object>(_ type: T.Type = T.self) -> Results<T> {
        
        let realm = try! Realm()
        let results = realm.objects(T.self)
        
        return results
    }
}


// MARK: Objects for Key

extension DatabaseManager {
    
    func objectsForKey<T: Object, V>(_ type: T.Type, key: String, value: V) -> Results<T> {
        
        return objects().filter("\(key) == %@", (value as AnyObject))
    }
    
    func objectsForKeys<T: Object, V>(_ type: T.Type, key: String, value: V) -> Results<T> {
        
        return objects().filter("\(key) IN %@", (value as AnyObject))
    }
    
    func objectForPrimaryKey<T: Object, V>(key: String, value: V) -> T? {
        
        return objects().filter("\(key) == %@", (value as AnyObject)).first
    }
}


// MARK: - Thread

extension DatabaseManager {
    
    func resolveThreadFor<T: Object>(_ results: Results<T>, _ completion: @escaping (_ results: Results<T>?) -> Void) {
        
        let ref = ThreadSafeReference(to: results)
        
        DispatchQueue.main.async {
        
            let realm = try! Realm()
            let resolvedResults = realm.resolve(ref)
            
            completion(resolvedResults)
        }
    }
}


// MARK: - Migrate

extension DatabaseManager {
    
    static func migrate() -> Realm.Configuration {
        
        return Realm.Configuration(schemaVersion: 13, migrationBlock: { _, _ in })
    }
}
