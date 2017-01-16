//
//  CoreDataStack.swift
//  EMCoreDataKit
//
//  Created by Elliott Minns on 09/09/2015.
//  Copyright (c) 2015 Elliott Minns. All rights reserved.
//

import Foundation
import CoreData


///  Describes a child managed object context.
public typealias ChildManagedObjectContext = NSManagedObjectContext

public enum StoreType {
    case persistent
    case inMemory
    
    var coreDataType: String {
        switch self {
        case .persistent:
            return NSSQLiteStoreType
            
        case . inMemory:
            return NSInMemoryStoreType
        }
    }
}


///  An instance of `CoreDataStack` encapsulates the entire Core Data stack for a SQLite store type.
///  It manages the managed object model, the persistent store coordinator, and the main managed object context.
///  It provides convenience methods for initializing a stack for common use-cases as well as creating child contexts.
public final class CoreDataStack: CustomStringConvertible {
    
    // MARK: Properties
    
    ///  The model for the stack.
    public let model: CoreDataModel
    
    ///  The main managed object context for the stack.
    public let managedObjectContext: NSManagedObjectContext
    
    ///  The persistent store coordinator for the stack.
    public let persistentStoreCoordinator: NSPersistentStoreCoordinator
    
    // MARK: Initialization
    
    ///  Constructs a new `CoreDataStack` instance with the specified model, storeType, options, and concurrencyType.
    ///
    ///  :param: model           The model describing the stack.
    ///  :param: storeType       A string constant that specifies the store type. The default parameter value is `NSSQLiteStoreType`.
    ///  :param: options         A dictionary containing key-value pairs that specify options for the store.
    ///                          The default parameter value contains `true` for the following keys: `NSMigratePersistentStoresAutomaticallyOption`, `NSInferMappingModelAutomaticallyOption`.
    ///  :param: concurrencyType The concurrency pattern with which the managed object context will be used. The default parameter value is `.MainQueueConcurrencyType`.
    ///
    ///  :returns: A new `CoreDataStack` instance.
    public init(model: CoreDataModel,
        storeType: StoreType = StoreType.persistent,
        options: [AnyHashable: Any]? = [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true],
        concurrencyType: NSManagedObjectContextConcurrencyType = .mainQueueConcurrencyType) {
            
            self.model = model
            self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model.managedObjectModel)
            
            let modelStoreURL: URL? = (storeType == .inMemory) ? nil : model.storeURL
            
            do {
                try self.persistentStoreCoordinator.addPersistentStore(ofType: storeType.coreDataType,
                    configurationName: nil, at: modelStoreURL, options: options)
            } catch _ {
                assert(true, "*** Error adding persistent store")
            }
            
            self.managedObjectContext = NSManagedObjectContext(concurrencyType: concurrencyType)
            self.managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
    }
    
    // MARK: Child contexts
    
    ///  Creates a new child managed object context with the specified concurrencyType and mergePolicyType.
    ///
    ///  :param: concurrencyType The concurrency pattern with which the managed object context will be used.
    ///                          The default parameter value is `.MainQueueConcurrencyType`.
    ///  :param: mergePolicyType The merge policy with which the manged object context will be used.
    ///                          The default parameter value is `.MergeByPropertyObjectTrumpMergePolicyType`.
    ///
    ///  :returns: A new child managed object context initialized with the given concurrency type and merge policy type.
    public func childManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType = .mainQueueConcurrencyType,
        mergePolicyType: NSMergePolicyType = .mergeByPropertyObjectTrumpMergePolicyType) -> ChildManagedObjectContext {
            
            let childContext = NSManagedObjectContext(concurrencyType: concurrencyType)
            childContext.parent = managedObjectContext
            childContext.mergePolicy = NSMergePolicy(merge: mergePolicyType)
            return childContext
    }
    
    // MARK: Printable
    
    /// :nodoc:
    public var description: String {
        get {
            return "<\(String(describing: CoreDataStack.self)): model=\(model)>"
        }
    }
    
}
