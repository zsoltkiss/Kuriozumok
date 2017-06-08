//
//  SearchResultOnMapViewController.swift
//  Kuriozumok
//
//  Created by Kiss Rudolf Zsolt on 2016. 01. 07..
//  Copyright © 2016. Kiss Rudolf Zsolt. All rights reserved.
//

import UIKit
import MapKit

class SearchResultOnMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    
    var results: Array<NameCard>?
    
//    var centerCoordinate: CLLocationCoordinate2D?
    
    var selectedNameCard: NameCard?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.addAnnotations()
        
//        self.mapView.showAnnotations(self.results!, animated: true)
    }

    // MARK: - MKMapViewDelegate protocol
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "NameCardPinAnnotationView"
        if annotation is NameCard {
            let someNC = annotation as! NameCard
            
            if let annotationView = self.mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
                annotationView.annotation = annotation
                
                
                
                print("Annotation view dequeing. NameCard assigned: \(someNC.name)")
                
                return annotationView
            } else {
//                let pinView = NameCardPinAnnotationView(aCard: someNC, reuseId: identifier)
                
                let pinView = MKPinAnnotationView(annotation: someNC, reuseIdentifier: identifier)
                
                pinView.isEnabled = true
                pinView.canShowCallout = true
                pinView.animatesDrop = true
                pinView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure) as UIButton
                
                
                print("Annotation view created. NameCard assigned: \(someNC.name)")
                
                return pinView

            }

        }
        
        return nil;

    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("Bubble tapped")
        
        if let nameCard = view.annotation as? NameCard {
            self.selectedNameCard = nameCard
        }
        
        self.performSegue(withIdentifier: "FromCalloutBubble", sender:view);
    }

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if "FromCalloutBubble" == segue.identifier {
            
            if let detailsVC = segue.destination as? NameCardDetailsViewController {
                detailsVC.selectedNameCard = self.selectedNameCard
            }
            
        }
    }

    
    // MARK: - Private methods
    
    fileprivate func addAnnotations() {
        
        for nameCard in self.results! {
            self.mapView.addAnnotation(nameCard)
        }
    
    
    }


}
