//
//  Flicker-Constants.swift
//  Virtual Tourist
//
//  Created by MIRKO on 3/22/16.
//  Copyright © 2016 XZM. All rights reserved.
//

import Foundation

extension Flickr {
    
    // Constants and params to be used by Flicker API
    
    struct Constants {
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME = "flickr.photos.search"
        static let API_KEY = "0b0ea239dcdb359b40bb4a0e9e898f45"
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
    }

    func defautlParams(pin: Pin) -> [String: AnyObject]{
        let parameters = [
            "method": Flickr.Constants.METHOD_NAME,
            "api_key": Flickr.Constants.API_KEY,
            "bbox": Flickr.sharedInstance().createBoundingBoxString(pin.coordinate),
            "safe_search": Flickr.Constants.SAFE_SEARCH,
            "extras": Flickr.Constants.EXTRAS,
            "format": Flickr.Constants.DATA_FORMAT,
            "nojsoncallback": Flickr.Constants.NO_JSON_CALLBACK,
            "per_page": 21
        ]
        
        return parameters as! [String : AnyObject]
    }
    
    func randomPageParams(pin: Pin, pages: Int) -> [String: AnyObject]{
        let pagesMax = (pages < 80) ? pages : 80;
        let randInt = Int(arc4random_uniform(UInt32(pagesMax)))
        
        let parameters = [
            "method": Flickr.Constants.METHOD_NAME,
            "api_key": Flickr.Constants.API_KEY,
            "bbox": Flickr.sharedInstance().createBoundingBoxString(pin.coordinate),
            "safe_search": Flickr.Constants.SAFE_SEARCH,
            "extras": Flickr.Constants.EXTRAS,
            "format": Flickr.Constants.DATA_FORMAT,
            "nojsoncallback": Flickr.Constants.NO_JSON_CALLBACK,
            "per_page": 21,
            "page": randInt
        ]
        
        return parameters as! [String : AnyObject]
    }
}