//
//  Category.swift
//  Kuriozumok
//
//  Created by Kiss Rudolf Zsolt on 2015. 11. 20..
//  Copyright © 2015. Kiss Rudolf Zsolt. All rights reserved.
//

import UIKit

class Category: NSObject {
    
    
    var title: String!
    var categoryId: Int!
    
    var selected: Bool = false
    
    init?(dictionary: Dictionary<String, AnyObject>) {
        
        let titleInDic = dictionary["title"] as? String
        let idInDic = dictionary["id"] as? Int
        
        
        if titleInDic != nil {
            self.title = titleInDic
            
        }
        
        if idInDic != nil {
            self.categoryId = idInDic
            
        }

        
        super.init()
        
        if self.title == nil || self.categoryId == nil {
            return nil
        }
        
    }
    
    
    convenience init?(t: String, i: Int) {
        var dic = Dictionary<String, AnyObject>()
        
        dic["title"] = t as AnyObject

        dic["id"] = i as AnyObject
        
        self.init(dictionary: dic)
        
    }

}
