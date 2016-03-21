//
//  Pin.swift
//  Virtual Tourist
//
//  Created by MIRKO on 3/21/16.
//  Copyright © 2016 XZM. All rights reserved.
//

import CoreData
import Foundation

class Pin : NSManagedObject {
    
    struct Keys {
        static let Lat = "lat"
        static let Long = "long"
        static let Title = "title"
    }
    @NSManaged var lat: Double
    @NSManaged var long: Double
    @NSManaged var title: String
    @NSManaged var photos: [Photo]
    
    // 4. Include this standard Core Data init method.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        title = dictionary[Keys.Title] as! String
        lat = dictionary[Keys.Lat] as! Double
        long = dictionary[Keys.Long] as! Double
    }
    
}