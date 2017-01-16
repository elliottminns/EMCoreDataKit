//
//  CoreDataExtenstions.swift
//  EMCoreDataKit
//
//  Created by Elliott Minns on 09/09/2015.
//  Copyright (c) 2015 Elliott Minns. All rights reserved.
//

import Foundation
import CoreData

///  A tuple value that describes the results of saving a managed object context.
///
///  :param: success A boolean value indicating whether the save succeeded. It is `true` if successful, otherwise `false`.
///  :param: error   An error object if an error occurred, otherwise `nil`.
public typealias ContextSaveResult = (success: Bool, error: NSError?)


///  Attempts to commit unsaved changes to registered objects to the specified context's parent store.
///  This method is performed *synchronously* in a block on the context's queue.
///  If the context returns `false` from `hasChanges`, this function returns immediately.
///
///  :param: context The managed object context to save.
///
///  :returns: A `ContextSaveResult` instance indicating the result from saving the context.
public func saveContextAndWait(_ context: NSManagedObjectContext) -> ContextSaveResult {
    
    if !context.hasChanges {
        return (true, nil)
    }
    
    var success: Bool = false
    
    context.performAndWait { () -> Void in
        do {
            try context.save()
            success = true
        } catch _ {
            success = false
            print("*** ERROR: [\(#line)\(#function) save managed object context:")
        }
    }
    
    return (success, NSError(domain: "", code: 1, userInfo: nil))
}


///  Attempts to commit unsaved changes to registered objects to the specified context's parent store.
///  This method is performed *asynchronously* in a block on the context's queue.
///  If the context returns `false` from `hasChanges`, this function returns immediately.
///
///  :param: context    The managed object context to save.
///  :param: completion The closure to be executed when the save operation completes.
public func saveContext(_ context: NSManagedObjectContext, completion: @escaping (ContextSaveResult) -> Void) {
    if !context.hasChanges {
        completion((true, nil))
        return
    }
    
    context.perform { () -> Void in

        let success: Bool
        
        do {
            try context.save()
            success = true
        } catch _ {
            success = false
        }
        
        if !success {
            print("*** ERROR: [\(#line)\(#function) Could not save managed object context:")
        }
        
        completion((success, NSError(domain: "", code: 2, userInfo: nil)))
    }
}


///  Returns the entity with the specified name from the managed object model associated with the specified managed object context’s persistent store coordinator.
///
///  :param: name    The name of an entity.
///  :param: context The managed object context to use.
///
///  :returns: The entity with the specified name from the managed object model associated with context’s persistent store coordinator.
public func entity(name: String, context: NSManagedObjectContext) -> NSEntityDescription {
    return NSEntityDescription.entity(forEntityName: name, in: context)!
}


///  An instance of `FetchRequest <T: NSManagedObject>` describes search criteria used to retrieve data from a persistent store.
///  This is a subclass of `NSFetchRequest` that adds a type parameter specifying the type of managed objects for the fetch request.
///  The type parameter acts as a phantom type.
open class FetchRequest <T: NSManagedObject>: NSFetchRequest<NSFetchRequestResult> {
    
    ///  Constructs a new `FetchRequest` instance.
    ///
    ///  :param: entity The entity description for the entities that this request fetches.
    ///
    ///  :returns: A new `FetchRequest` instance.
    public init(entity: NSEntityDescription) {
        super.init()
        self.entity = entity
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


///  A `FetchResult` represents the result of executing a fetch request.
///  It has one type parameter that specifies the type of managed objects that were fetched.
public struct FetchResult <T: NSManagedObject> {
    
    ///  Specifies whether or not the fetch succeeded.
    public let success: Bool
    
    ///  An array of objects that meet the criteria specified by the fetch request.
    ///  If the fetch is unsuccessful, this array will be empty.
    public let objects: [T]
    
    ///  If unsuccessful, specifies an error that describes the problem executing the fetch. Otherwise, this value is `nil`.
    public let error: NSError?
}


///  Executes the fetch request in the given context and returns the result.
///
///  :param: request A fetch request that specifies the search criteria for the fetch.
///  :param: context The managed object context in which to search.
///
///  :returns: A instance of `FetchResult` describing the results of executing the request.
public func fetch <T: NSManagedObject>(request: FetchRequest<T>, inContext context: NSManagedObjectContext) -> FetchResult<T> {
    
    var results: [AnyObject]?
    
    context.performAndWait { () -> Void in
        do {
            try results = context.fetch(request)
        } catch _ {
            results = nil
        }
    }
    
    if let results = results {
        return FetchResult(success: true, objects: results as! [T], error: nil)
    } else {
        print("*** ERROR: [\(#line)] \(#function) Error while executing fetch request: ")
    }
    
    return FetchResult(success: false, objects: [], error: NSError(domain: "", code: 1, userInfo: nil))
}


///  Deletes the objects from the specified context.
///  When changes are committed, the objects will be removed from their persistent store.
///  You must save the context after calling this function to remove objects from the store.
///
///  :param: objects The managed objects to be deleted.
///  :param: context The context to which the objects belong.
public func deleteObjects <T: NSManagedObject>(_ objects: [T], inContext context: NSManagedObjectContext) {
    
    if objects.count == 0 {
        return
    }
    
    context.performAndWait { () -> Void in
        for each in objects {
            context.delete(each)
        }
    }
}
