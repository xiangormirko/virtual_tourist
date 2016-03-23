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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
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
        
        if (NSUserDefaults.standardUserDefaults().doubleForKey("lat") != 0.0 && NSUserDefaults.standardUserDefaults().doubleForKey("long") != 0.0) {
            mapView.setRegion(mapPersistence(), animated: true)
        } else {
            print("no initial pref")
            return
        }
        
        editLabel.hidden = true
//
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func longTap(sender: UILongPressGestureRecognizer) {
        
        if sender.state == .Ended {
            let location = sender.locationInView(mapView)
            let coordinate = mapView.convertPoint(location, toCoordinateFromView: mapView)
        
//            let annotation = MKPointAnnotation()
//            annotation.title = "View Photo Collection!"
//            annotation.coordinate = coordinate
//            mapView.addAnnotation(annotation)
            persistMap()
            
            let dictionary: [String : AnyObject] = [
                Pin.Keys.Title : "View Photo Collection!",
                Pin.Keys.Lat : coordinate.latitude,
                Pin.Keys.Long : coordinate.longitude
            ]
            // Now we create a new Pin, using the shared Context
            let newPin = Pin(dictionary: dictionary, context: sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
            mapView.addAnnotation(newPin)
            
            
            let parameters = Flickr.sharedInstance().defautlParams(newPin)
            
            Flickr.sharedInstance().taskForResource(parameters) {JSONResult, error  in
                if let error = error {
                    print(error)
                } else {
                    let photoContainer = JSONResult.valueForKey("photos")
    
                    if let photosDictionaries = photoContainer!.valueForKey("photo") as? [[String : AnyObject]] {
                        
                        // Parse the array of movies dictionaries
                        let _ = photosDictionaries.map() { (dictionary: [String : AnyObject]) -> Photo in
                            let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                            
                            photo.pin = newPin
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
    }
    
    @IBAction func editAction(sender: AnyObject) {

        if editMode {
            editMode = false
        } else {
            editMode = true
        }
        
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
    
    
    // Step 1: This would be a nice place to paste the lazy fetchedResultsController
    
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
        print("Persisting map!")
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
        }
        else {
            pinView!.annotation = annotation
            
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if editMode == true {
            let pin = view.annotation as! Pin
            sharedContext.deleteObject(pin)
            saveContext()
            mapView.removeAnnotation(pin)
        }
    }
    
    // pin callout press action
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("pin annotation tapped")
        let mapCollectionController = self.storyboard!.instantiateViewControllerWithIdentifier("CollectionMapViewController") as! CollectionMapViewController
        mapCollectionController.region = self.mapView.region
        mapCollectionController.annotation = view.annotation
        mapCollectionController.pin = view.annotation as! Pin
        
        self.navigationController!.pushViewController(mapCollectionController, animated: true)
        
    }

    

}

