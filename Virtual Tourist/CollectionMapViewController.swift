//
//  CollectionMapViewController.swift
//  Virtual Tourist
//
//  Created by MIRKO on 3/21/16.
//  Copyright © 2016 XZM. All rights reserved.
//

import Foundation
import MapKit


class CollectionMapViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var region : MKCoordinateRegion? = nil
    var annotation : MKAnnotation? = nil
    
    
    var photos = []
    var pin: Pin!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
    
        mapView.setRegion(region!, animated: true)
        mapView.setCenterCoordinate((annotation?.coordinate)!, animated: true)
        mapView.addAnnotation(annotation!)
       
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //deque and use cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath)
    
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // present detail view when a cell is pressed
//        let detailController = self.storyboard!.instantiateViewControllerWithIdentifier("MemeDetailViewController") as! MemeDetailViewController
//        detailController.meme = self.memes[indexPath.row]
//        self.navigationController!.pushViewController(detailController, animated: true)
    }
    
    
}