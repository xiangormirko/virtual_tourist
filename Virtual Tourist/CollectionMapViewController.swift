//
//  CollectionMapViewController.swift
//  Virtual Tourist
//
//  Created by MIRKO on 3/21/16.
//  Copyright © 2016 XZM. All rights reserved.
//

import Foundation
import MapKit
import CoreData


class CollectionMapViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    var selectedIndexes = [NSIndexPath]()
    
    var region : MKCoordinateRegion? = nil
    var annotation : MKAnnotation? = nil
    
    
    var photos = []
    var pin: Pin!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
    
        mapView.setRegion(region!, animated: true)
        mapView.setCenterCoordinate((annotation?.coordinate)!, animated: true)
        mapView.addAnnotation(annotation!)
        
        // Step 2: Perform the fetch
        
        do {
            try fetchedResultsController.performFetch()

        } catch {
            print("Unresolved error \(error)")
            abort()
        }
        // Step 6: Set the delegate to this view controller
        fetchedResultsController.delegate = self

       
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if pin.photos.isEmpty {
            
            let parameters = [
                "method": Flickr.Constants.METHOD_NAME,
                "api_key": Flickr.Constants.API_KEY,
                "bbox": Flickr.sharedInstance().createBoundingBoxString(annotation!.coordinate),
                "safe_search": Flickr.Constants.SAFE_SEARCH,
                "extras": Flickr.Constants.EXTRAS,
                "format": Flickr.Constants.DATA_FORMAT,
                "nojsoncallback": Flickr.Constants.NO_JSON_CALLBACK
            ]
            
            Flickr.sharedInstance().taskForResource(parameters) {JSONResult, error  in
                if let error = error {
                    print(error)
                } else {
                    //                    print(JSONResult)
                    let photoContainer = JSONResult.valueForKey("photos")
                    if let photosDictionaries = photoContainer!.valueForKey("photo") as? [[String : AnyObject]] {
                        
                        // Parse the array of movies dictionaries
                        let _ = photosDictionaries.map() { (dictionary: [String : AnyObject]) -> Photo in
                            let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                            
                            photo.pin = self.pin
                            print(photo)
                            return photo
                        }
                        
                        
                        // Save the context
                        self.saveContext()
                        
                    } else {
                        let error = NSError(domain: "Photo for Pin Parsing. Cant find photo in \(JSONResult)", code: 0, userInfo: nil)
                        print(error)
                    }
                }
            }

        }
        
        collectionView?.reloadData()
    }
    
    // MARK: - Core Data Convenience
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    
    // Step 1: This would be a nice place to paste the lazy fetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        print("got so many sections: \(self.fetchedResultsController.sections?.count)")
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
        
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo

        
        // If the cell is "selected" it's color panel is grayed out
        // we use the Swift `find` function to see if the indexPath is in the array
        cell.photoPanel.contentMode = UIViewContentMode.ScaleAspectFill
        
        // Custom white border
        cell.photoPanel.layer.borderWidth = 5
        cell.photoPanel.layer.borderColor = UIColor.whiteColor().CGColor
        
        cell.photoPanel!.image = nil
        
        if photo.url_m == "" {
            print("no image")
        } else if photo.pinImage != nil {
            cell.photoPanel!.image = photo.pinImage
        }
        else {
            // Start the task that will eventually download the image
            _ = Flickr.sharedInstance().taskForImageWithSize(photo.url_m) { data, error in
                
                if let error = error {
                    print("Poster download error: \(error.localizedDescription)")
                }
                
                if let data = data {
                    // Craete the image
                    let image = UIImage(data: data)
                    
                    // update the model, so that the infrmation gets cashed
                    photo.pinImage = image
                    
                    // update the cell later, on the main thread
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.photoPanel!.image = image
                    }
                }
            }

        }
        
        
    }
    
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        print("number Of Cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
//        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo

        //deque and use cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCell
        self.configureCell(cell, atIndexPath: indexPath)
        
    
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        print("hellot")
        
        
        // present detail view when a cell is pressed
//        let detailController = self.storyboard!.instantiateViewControllerWithIdentifier("MemeDetailViewController") as! MemeDetailViewController
//        detailController.meme = self.memes[indexPath.row]
//        self.navigationController!.pushViewController(detailController, animated: true)
    }
    
    
    
}