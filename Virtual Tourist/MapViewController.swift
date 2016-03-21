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
    

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "persistMap", name: UIApplicationWillResignActiveNotification, object: nil)
        
        // Step 2: Perform the fetch
        do {
            try fetchedResultsController.performFetch()
            print(fetchedResultsController.fetchedObjects)
            
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
//        mapView.setRegion(MapPersistence(), animated: true)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func longTap(sender: UILongPressGestureRecognizer) {
        
        if sender.state == .Ended {
            let location = sender.locationInView(mapView)
            let coordinate = mapView.convertPoint(location, toCoordinateFromView: mapView)
        
            let annotation = MKPointAnnotation()
            annotation.title = "View Photo Collection!"
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            persistMap()
            
            let dictionary: [String : AnyObject] = [
                Pin.Keys.Title : "View Photo Collection!",
                Pin.Keys.Lat : annotation.coordinate.latitude,
                Pin.Keys.Long : annotation.coordinate.longitude
            ]
            // Now we create a new Pin, using the shared Context
            _ = Pin(dictionary: dictionary, context: sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
            
            
            let parameters = [
                "method": Flickr.Constants.METHOD_NAME,
                "api_key": Flickr.Constants.API_KEY,
                "bbox": Flickr.sharedInstance().createBoundingBoxString(annotation.coordinate),
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
                }
            }
            
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
        
        print(lat, long, latDelta, longDelta)
        
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
    
    // pin callout press action
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            print("pin tapped")
        let mapCollectionController = self.storyboard!.instantiateViewControllerWithIdentifier("CollectionMapViewController") as! CollectionMapViewController
        mapCollectionController.region = self.mapView.region
        mapCollectionController.annotation = view.annotation
        
        self.navigationController!.pushViewController(mapCollectionController, animated: true)
        
    }

    

}
