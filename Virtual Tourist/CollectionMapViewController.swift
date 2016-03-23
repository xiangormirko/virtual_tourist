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
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!

    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    // Layout the collection view
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.collectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }
    
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
                            print("no image donwloading: \(photo)")
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
        CoreDataStackManager.sharedInstance().saveContext()
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
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
        
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo

        // If the cell is "selected" it's color panel is grayed out
        // we use the Swift `find` function to see if the indexPath is in the array
        cell.photoPanel.contentMode = UIViewContentMode.ScaleAspectFill
        
        // Custom white border
        cell.photoPanel.layer.borderWidth = 3
        cell.photoPanel.layer.borderColor = UIColor.whiteColor().CGColor
        
        cell.photoPanel!.image = nil
        
        if photo.url_m == "" {
            print("no image")
        } else if photo.pinImage != nil {
            cell.photoPanel!.image = photo.pinImage
            print("photo pin image: \(photo.pinImage)")
        }
        else {
            // Start the task that will eventually download the image
            let task = Flickr.sharedInstance().taskForImageWithSize(photo.url_m) { data, error in
                
                if let error = error {
                    print("Poster download error: \(error.localizedDescription)")
                }
                
                if let data = data {
                    // Craete the image
                    let image = UIImage(data: data)
                    
                    // update the model, so that the infrmation gets cashed
                    photo.pinImage = image
                    print("image fetched")
                    self.saveContext()
                    // update the cell later, on the main thread
                    print("image fetched")
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        cell.photoPanel!.image = image
                        
                    }
                }
            }
            cell.taskToCancelifCellIsReused = task
        }
        
        
    }
    
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
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
        
        
        // present detail view when a cell is pressed
//        let detailController = self.storyboard!.instantiateViewControllerWithIdentifier("MemeDetailViewController") as! MemeDetailViewController
//        detailController.meme = self.memes[indexPath.row]
//        self.navigationController!.pushViewController(detailController, animated: true)
    }
    

    
    // MARK: - Fetched Results Controller Delegate
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }
    
    // The second method may be called multiple times, once for each Photo object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            print("Insert an item")
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete an item")
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item.")
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
        default:
            break
        }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    
    
}