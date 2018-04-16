//
//  MapViewController.swift
//  BuckIt
//
//  Created by WilliamH on 1/23/18.
//  Copyright © 2018 Samnang Sok. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    private let locationManager = CLLocationManager()
    private var currentCoordinate: CLLocationCoordinate2D?
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var search: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        FirebaseDataContoller.sharedInstance.mapViewObj = self.mapView
        configureLocationServices()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Did get latest location")
        guard let latestLocation = locations.first else { return }
        
        if currentCoordinate == nil {
            zoomToLatestLocation(with: latestLocation.coordinate)
            // Add the annotations to the map via Firebase Singleton
            FirebaseDataContoller.sharedInstance.fetchActivitiesToMap()
        }
        print("Current # of pins: \(FirebaseDataContoller.sharedInstance.activitiesPin.count)")
        currentCoordinate = latestLocation.coordinate
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Status changed")
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            beginLocationUpdates(locationManager: manager)
        }
    }
    
    // Customized pins starts here ~ This implementation behaves like an UIView
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {        
        let annotationIdentifier = "ActivityAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
    
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
        }
        
        // Display pin icon for user's current location
        if annotation === mapView.userLocation {
            annotationView?.image = UIImage(named: "current_user.png")
        }
        
        // Display pin icon for all the activities from the Firebase
        if let annotationView = annotationView, let _ = annotation as? ActivityPin {
            for activity in FirebaseDataContoller.sharedInstance.activitiesPinGetter {
                if let title = annotation.title, title == activity.title {
                    annotationView.image = UIImage(named: "\(activity.imageName)")
                }
            }
        }
        
        annotationView?.canShowCallout = true
        return annotationView
    }
    
    // Display a messege in the console for the pin selected on the map
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("Selected annotation: \(String(describing: view.annotation?.title))")
    }
    
    // This helper method allows to request permission to track user's location
    private func configureLocationServices() {
        locationManager.delegate = self
        let status = CLLocationManager.authorizationStatus()
        
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse {
            beginLocationUpdates(locationManager: locationManager)
        }
    }
    
    // This helper method allows to starts gathering user's location
    private func beginLocationUpdates(locationManager: CLLocationManager) {
        mapView.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    // This helper method allows to auto-zoom the map once it's loaded
    private func zoomToLatestLocation(with coordinate: CLLocationCoordinate2D) {
        let zoomLevel: Double = 3000
        let zoomRegion = MKCoordinateRegionMakeWithDistance(coordinate, zoomLevel, zoomLevel)
        mapView.setRegion(zoomRegion, animated: true)
    }
    
    //needed to dismiss the keyboard
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        search.endEditing(true)
    }
    
}
