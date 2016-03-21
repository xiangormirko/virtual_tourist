//
//  Flicker-Constants.swift
//  Virtual Tourist
//
//  Created by MIRKO on 3/22/16.
//  Copyright © 2016 XZM. All rights reserved.
//

import Foundation

extension Flickr {
    
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
}