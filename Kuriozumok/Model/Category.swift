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
        if let localizedTitles = dictionary["title"] as? [String:Any] {
            if let currentLanguage = Locale.current.languageCode, currentLanguage == "hu", let titleHu = localizedTitles["hu"] as? String {
                self.title = titleHu
            } else {
                if let titleEn = localizedTitles["en"] as? String {
                    self.title = titleEn
                }
            }
        }
        
        if let idInDic = dictionary["id"] as? Int {
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
