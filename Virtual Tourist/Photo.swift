//
//  Photo.swift
//  Virtual Tourist
//
//  Created by MIRKO on 3/21/16.
//  Copyright © 2016 XZM. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Photo: NSManagedObject {
    // Custom Core Data Photo class
    struct Keys {
        static let ID = "id"
        static let Url_M = "url_m"
        static let Title = "title"
    }
    
    @NSManaged var id: NSNumber
    @NSManaged var url_m: String
    @NSManaged var title: String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        let idStr = dictionary[Keys.ID] as! String
        let idInt = Int(idStr)
        
        title = dictionary[Keys.Title] as! String
        id = idInt!
        url_m = dictionary[Keys.Url_M] as! String
    }
    
    // delete elements in documents dir at deletion
    override func prepareForDeletion() {
        pinImage = nil
    }

    
    // UIImage storage
    var pinImage: UIImage? {
        
        get {
            return Flickr.Caches.imageCache.imageWithIdentifier("\(id).png")
        }
        
        set {
            Flickr.Caches.imageCache.storeImage(newValue, withIdentifier: "\(id).png")
        }
    }
    
}