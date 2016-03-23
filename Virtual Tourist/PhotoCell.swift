//
//  PhotoCell.swift
//  Virtual Tourist
//
//  Created by MIRKO on 3/22/16.
//  Copyright © 2016 XZM. All rights reserved.
//

import Foundation
import UIKit

class PhotoCell: UICollectionViewCell {
    
    // Custom cell with ability to cancel tasks
    @IBOutlet weak var photoPanel: UIImageView!
    
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
    
}