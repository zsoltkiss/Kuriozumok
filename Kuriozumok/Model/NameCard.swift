//
//  NameCard.swift
//  Kuriozumok
//
//  Created by Kiss Rudolf Zsolt on 2015. 11. 24..
//  Copyright © 2015. Kiss Rudolf Zsolt. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class NameCard: NSObject, MKAnnotation {
    
    var name: String!
    var category: Category?
    var longitude: Double!
    var latitude: Double!
    var address: String?
    var phone: String?
    var cellPhone: String?
    var email: String?
    var cardDescription: String?
    var webPage: String?
    
    var comments: Array<Comment>?
    var imageUrls: Array<String>?
    
    // Server side calculated value: distance from town in search criteria
    var distance: Double?
    
    var nameCardId: Int!
    
    // MKAnnotation proptocol properties
    var title: String? {
        
        return self.name
        
    }
    var subtitle: String? {
        return self.address
    }
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2DMake(self.latitude, self.longitude)
        }
    }
    
    init(dictionary: Dictionary<String, AnyObject>) {
        
        if let categoryDic = dictionary["category"] as? Dictionary<String, AnyObject> {
            self.category = Category.instance(from: categoryDic, level: 0)
        }
        
        if let commentsArray = dictionary["comments"] as? Array<Dictionary<String, AnyObject>> {
            print("COMMENTS: \(commentsArray)")
            
            for aDic in commentsArray {
                let someComment = Comment(dictionary: aDic)
                
                if self.comments == nil {
                    self.comments = [Comment]()
                }
                
                self.comments?.append(someComment)
            }
            
        }
        
        if let desc = dictionary["description"] as? String {
            self.cardDescription = desc
        }
        
        if let dist = dictionary["distance"] as? String {
            // distance calculated by the server
            self.distance = (dist as NSString).doubleValue
        }
        
        if let emailAddress = dictionary["email"] as? String {
            self.email = emailAddress
        }
        
        if let cardId = dictionary["id"] as? Int {
            self.nameCardId = cardId
        }
        
        if let urlsForImages = dictionary["images_url"] as? Array<String> {
            self.imageUrls = urlsForImages
        }
        
        if let lat = dictionary["latitude"] as? String {
            self.latitude = (lat as NSString).doubleValue
        }
        
        if let lng = dictionary["longitude"] as? String {
            self.longitude = (lng as NSString).doubleValue
        }
        
        if let fullAddress = dictionary["street_address"] as? String {
            self.address = fullAddress
        }
        
        if let strPhone = dictionary["telephone"] as? String {
            self.phone = strPhone
        }
        
        if let title = dictionary["title"] as? String {
            self.name = title
        }
        
        if let web = dictionary["web"] as? String {
            self.webPage = web
        }
    }
    
    func distanceFromLocationInMeters(_ someLocation: CLLocation?) -> Double {
        if someLocation == nil {
            return -1
        }
        
        let kuriozumLocation =  CLLocation(latitude: self.latitude, longitude: self.longitude)
        
        let meters = someLocation?.distance(from: kuriozumLocation)
        
        return Double(meters!)
        
    }
    
    

}
