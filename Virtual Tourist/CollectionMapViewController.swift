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
    
    // track selected inded
    var selectedIndexes = [NSIndexPath]()
    
    var region : MKCoordinateRegion? = nil
    var annotation : MKAnnotation? = nil
        
    var photos = []
    var pin: Pin!
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!

    
    @IBOutlet weak var collectionButton: UIButton!
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

        collectionView.delegate = self
        collectionView.dataSource = self
    
        mapView.setRegion(region!, animated: true)
        mapView.setCenterCoordinate((annotation?.coordinate)!, animated: true)
        mapView.addAnnotation(annotation!)
        
        // Perform the fetch
        
        do {
            try fetchedResultsController.performFetch()

        } catch {
            print("Unresolved error \(error)")
            abort()
        }
        
        // Set the delegate to this view controller
        fetchedResultsController.delegate = self

        updateBottomButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if pin.photos.isEmpty {
            fetchData()
        }

    }
    
    
    // Action to create a new set of photo collection
    @IBAction func newCollection(sender: AnyObject) {
    
        
        if selectedIndexes.isEmpty {
            for obj in fetchedResultsController.fetchedObjects! {
                let object = obj as! Photo
                self.sharedContext.deleteObject(object)
            }
            saveContext()
            
            fetchData()
            do {
                try fetchedResultsController.performFetch()
                
            } catch {
                print("Unresolved error \(error)")
                abort()
            }
        } else {
            
            //if pics are selected, delete selected photos
            deleteSelectedPhotos()
        }
        

    }
    
    
    // MARK: - Core Data Convenience
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    
    // This would be a nice place to paste the lazy fetchedResultsController
    
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
    
    
    // Convenience method to set cell UI
    func configureCell(cell: PhotoCell, atIndexPath indexPath: NSIndexPath) {
    
        let photoImage = UIImage(named: "placeholder.png")
        cell.photoPanel!.image = photoImage
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        cell.photoPanel.contentMode = UIViewContentMode.ScaleAspectFill
        
        // Custom white border
        cell.photoPanel.layer.borderWidth = 3
        cell.photoPanel.layer.borderColor = UIColor.whiteColor().CGColor
        
        
        // if cell is selected, reduce alpha
        if let _ = selectedIndexes.indexOf(indexPath) {
            cell.photoPanel.alpha = 0.2
        } else {
            cell.photoPanel.alpha = 1.0
        }
        
        if photo.url_m == "" {
            print("no image")
        } else if photo.pinImage != nil {
            cell.photoPanel!.image = photo.pinImage
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
                    self.saveContext()
                    // update the cell later, on the main thread
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

        //deque and use cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCell
        self.configureCell(cell, atIndexPath: indexPath)
        
    
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
        configureCell(cell, atIndexPath: indexPath)
        
        // And update the buttom button
        updateBottomButton()
    }
    

    
    // MARK: - Fetched Results Controller Delegate

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
 
    }
    

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            break
        default:
            break
        }
    }
    

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        // perform batch update
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
    
    func fetchData() {
        // Convenience method to fetch data if not present, if multiple pages, select random page
        
        let parameters = Flickr.sharedInstance().defautlParams(self.pin)
        
        Flickr.sharedInstance().taskForResource(parameters) {JSONResult, error  in
            if let error = error {
                print(error)
            } else {
                let photoContainer = JSONResult.valueForKey("photos")
                let photoPages = photoContainer?.valueForKey("pages")
                
                if photoPages as! Int > 1 {
                    //If more than 1 page select a random page using convenience method
                    
                    let params = Flickr.sharedInstance().randomPageParams(self.pin, pages: photoPages as! Int)
                    
                    Flickr.sharedInstance().taskForResource(params) {JSONResult, error  in
                        if let error = error {
                            print(error)
                        } else {
                            let photoContainer = JSONResult.valueForKey("photos")
                            if let photosDictionaries = photoContainer!.valueForKey("photo") as? [[String : AnyObject]] {
                                
                                // Parse the array of movies dictionaries
                                let _ = photosDictionaries.map() { (dictionary: [String : AnyObject]) -> Photo in
                                    let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                                    
                                    photo.pin = self.pin
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
                } else {
                
                if let photosDictionaries = photoContainer!.valueForKey("photo") as? [[String : AnyObject]] {
                    
                    // Parse the array of movies dictionaries
                    let _ = photosDictionaries.map() { (dictionary: [String : AnyObject]) -> Photo in
                        let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                        
                        photo.pin = self.pin
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
    }
    
    func deleteSelectedPhotos() {
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
        }
        
        selectedIndexes = [NSIndexPath]()
    }
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            collectionButton.setTitle("Remove seletcted photos", forState: UIControlState.Normal)
        } else {
            collectionButton.setTitle("Reload with new collection", forState: UIControlState.Normal)
        }
    }
    
    
}