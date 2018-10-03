//
//  CacheService.swift
//  dbr
//
//  Created by Ray Krow on 10/3/18.
//  Copyright © 2018 Kirk. All rights reserved.
//

import Foundation


struct CacheService {
    
    let destination: URL
    private let queue = OperationQueue()
    
    struct CacheModel<T: Codable>: Codable {
        let ttd: Double
        let payload: T
    }
    
    init() {
        // Create the URL for the location of the cache resources
        let documentFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        self.destination = URL(fileURLWithPath: documentFolder).appendingPathComponent("dbr_cahce", isDirectory: true)
        
        let fileManager = FileManager.default
        
        do {
            try fileManager.createDirectory(at: destination, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            fatalError("Unable to create cache directory: \(error)")
        }
    }
    
    func persist<T: Codable>(_ data: T, key: String, ttl: Int = 86400) -> Void {
        
        let url = destination.appendingPathComponent(key, isDirectory: false)
        let ttd = Date().timeIntervalSince1970 + Double(ttl)
        let model = CacheModel(ttd: ttd, payload: data)
        
        let operation = BlockOperation {
            do {
                try JSONEncoder().encode(model).write(to: url, options: [.atomicWrite])
            } catch {
                fatalError("Failed to write item to cache: \(error)")
            }
        }
        
        queue.addOperation(operation)
    }
    
    func retrieve<T: Codable>(_ key: String) -> T? {
        print("Checking cache...")
        guard
            let data = try? Data(contentsOf: destination.appendingPathComponent(key, isDirectory: false)),
            let model = try? JSONDecoder().decode(CacheModel<T>.self, from: data)
            else { return nil }

        let rightNow = Date().timeIntervalSince1970
        guard model.ttd > rightNow else { return nil }
        
        return model.payload
    }
    
}
