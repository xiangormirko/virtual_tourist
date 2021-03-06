//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by MIRKO on 3/21/16.
//  Copyright © 2016 XZM. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var editLabel: UILabel!
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    var editMode = false
    var currentPin: Pin!
    var tempAnnotation = MKPointAnnotation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        // edit label initially hidden
        editLabel.hidden = true
        
        // sign up for resignation activities
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "persistMap", name: UIApplicationWillResignActiveNotification, object: nil)
        
        // Step 2: Perform the fetch
        do {
            try fetchedResultsController.performFetch()
            for pin in fetchedResultsController.fetchedObjects! {
                let pin = pin as! Pin
                mapView.addAnnotation(pin)
            }
            

            
        } catch {
            print("Unresolved error \(error)")
            abort()
        }
        
        // Step 9: set the fetchedResultsController.delegate = self
        fetchedResultsController.delegate = self
        
        // if NSUserDefaults found for map zoom preferences, set them
        if (NSUserDefaults.standardUserDefaults().doubleForKey("lat") != 0.0 && NSUserDefaults.standardUserDefaults().doubleForKey("long") != 0.0) {
            mapView.setRegion(mapPersistence(), animated: true)
        } else {
            return
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // Recognize long taps to drop a pin
    @IBAction func longTap(sender: UILongPressGestureRecognizer) {
        
        
        switch sender.state {
        
        case .Began:
            
            // create a temporary annotaion point to display
            
            let location = sender.locationInView(mapView)
            let coordinate = mapView.convertPoint(location, toCoordinateFromView: mapView)
            
            tempAnnotation.coordinate = coordinate

            dispatch_async(dispatch_get_main_queue(), {
                self.mapView.addAnnotation(self.tempAnnotation)
            })
            break
            
        case .Changed:
            
                // track annotation changes
                let location = sender.locationInView(mapView)
                let coordinate = mapView.convertPoint(location, toCoordinateFromView: mapView)
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.tempAnnotation.coordinate = coordinate
                })
            
        
        
        case .Ended:
            
            
            // remove temp annotation and create a real Pin instance
            mapView.removeAnnotation(tempAnnotation)
        
            // persist map zoom level
            persistMap()
            
            let dictionary: [String : AnyObject] = [
                Pin.Keys.Title : "View Photo Collection!",
                Pin.Keys.Lat : tempAnnotation.coordinate.latitude,
                Pin.Keys.Long : tempAnnotation.coordinate.longitude
            ]
            // Now we create a new Pin, using the shared Context
            let newPin = Pin(dictionary: dictionary, context: sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
            mapView.addAnnotation(newPin)
            
            // Convenience params for Flicker API request
            let parameters = Flickr.sharedInstance().defautlParams(newPin)
            
            
            // Request using convenience method
            Flickr.sharedInstance().taskForResource(parameters) {JSONResult, error  in
                if let error = error {
                    print(error)
                } else {
                    let photoContainer = JSONResult.valueForKey("photos")
    
                    if let photosDictionaries = photoContainer!.valueForKey("photo") as? [[String : AnyObject]] {
                        
                        // Parse the array of movies dictionaries
                        let _ = photosDictionaries.map() { (dictionary: [String : AnyObject]) -> Photo in
                            let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                            
                            // Associate photos with Pin
                            photo.pin = newPin
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
            
        default:
            return
            
        }

    }
    
    @IBAction func editAction(sender: AnyObject) {

        // reconize and switch edit mode
        if editMode {
            editMode = false
        } else {
            editMode = true
        }
        
        // set relative UI
        if editMode {
            editButton.title = "Done"
            editLabel.hidden = false
        } else {
            editButton.title = "Edit"
            editLabel.hidden = true
        }
    }
    
    // MARK: - Core Data Convenience
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return fetchedResultsController
        
    }()

    
    // Persist map preferences: zoom, center
    func persistMap() {
        let lat = mapView.region.center.latitude
        let long = mapView.region.center.longitude
        
        let latDelta = mapView.region.span.latitudeDelta
        let longDelta = mapView.region.span.latitudeDelta
        
        let MapPref = NSUserDefaults.standardUserDefaults()
        MapPref.setDouble(lat, forKey: "lat")
        MapPref.setDouble(long, forKey: "long")
        
        MapPref.setDouble(latDelta, forKey: "latDelta")
        MapPref.setDouble(longDelta, forKey: "longDelta")
        
    }
    
    // Retrieve map preferences
    func mapPersistence() -> MKCoordinateRegion {
        let defaults = NSUserDefaults.standardUserDefaults()
        let lat = defaults.doubleForKey("lat")
        let long = defaults.doubleForKey("long")
        let latDelta = defaults.doubleForKey("latDelta")
        let longDelta = defaults.doubleForKey("longDelta")

        
        let center = CLLocationCoordinate2D(latitude: lat, longitude: long)
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta)
        let region = MKCoordinateRegion(center: center, span: span)
        
        return region
    }
    
    
    
    // pin annotations
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.redColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
            pinView!.draggable = true
            pinView!.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
            
        }
        
        return pinView
    }
    
    // If pin is touched in edit mode, remove it
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if editMode == true {
            let pin = view.annotation as! Pin
            sharedContext.deleteObject(pin)
            saveContext()
            mapView.removeAnnotation(pin)
            
        }
    }
    
    
    
    // pin callout press action to view collection
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let mapCollectionController = self.storyboard!.instantiateViewControllerWithIdentifier("CollectionMapViewController") as! CollectionMapViewController
        mapCollectionController.region = self.mapView.region
        mapCollectionController.annotation = view.annotation
        mapCollectionController.pin = view.annotation as! Pin
        
        self.navigationController!.pushViewController(mapCollectionController, animated: true)
        
    }

    

}

