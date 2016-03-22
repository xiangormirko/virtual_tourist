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
    
    
    @IBOutlet weak var photoPanel: UIImageView!
    
    
    var color: UIColor {
        set {
            self.photoPanel.backgroundColor = UIColor.whiteColor()
        }
        
        get {
            return self.photoPanel.backgroundColor ?? UIColor.whiteColor()
        }
    }
}