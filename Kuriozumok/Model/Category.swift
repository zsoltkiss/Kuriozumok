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
    var children: [Category]?
    
    weak var parent: Category?
    
    private (set) var level: Int = 0
    
    var isSelected: Bool = false {
        didSet {
            
            if shouldStatePropagate {
                if let realChildren = children {
                    for aChild in realChildren {
                        aChild.isSelected = self.isSelected
                    }
                }
            }
            
            if let myParent = self.parent {
                if !self.isSelected {
                    myParent.childDeselected(self)
                } else {
                    myParent.checkChildrenState()
                }
            }
            
            if !shouldStatePropagate {
                shouldStatePropagate = true
            }
        }
    }
    
    private var shouldStatePropagate = true
    
    override var description: String {
        var strChildren = ""
        
        if let array = self.children {
            let titlesOfChildren = array.map({ (aChild) -> String in
                return aChild.description
            })
            
            for t in titlesOfChildren {
                strChildren += "\(t),"
            }
        }
        
        return "\(title) [\(strChildren)]"
    }
    
    private func childDeselected(_ someChild: Category) {
        self.shouldStatePropagate = false
        self.isSelected = false
    }
    
    private func checkChildrenState() {
        tempContainer = [Category]()
        Category.fetchAllChildren(for: self)
        let filteredArray = tempContainer.filter { $0.isSelected == false }
        
        if filteredArray.count == 0 {
            self.isSelected = true
        }
        
    }
    
    static func fetchAllChildren(for category: Category) {
        if let realChildren = category.children {
            for aChild in realChildren {
                tempContainer.append(aChild)
                if aChild.children != nil && aChild.children!.count > 0 {
                    fetchAllChildren(for: aChild)
                }
            }
        }
    }
    
    static func instance(from dictionary: [String:AnyObject], level: Int) -> Category? {
        
        let newCat = Category()
        newCat.level = level
        
        if let localizedTitles = dictionary["title"] as? [String:Any] {
            if let currentLanguage = Locale.current.languageCode, currentLanguage == "hu", let titleHu = localizedTitles["hu"] as? String {
                newCat.title = titleHu
            } else {
                if let titleEn = localizedTitles["en"] as? String {
                    newCat.title = titleEn
                }
            }
        }
        
        if let idInDic = dictionary["id"] as? Int {
            newCat.categoryId = idInDic
        }
        
        if let subCats = dictionary["children"] as? [[String:AnyObject]] {
            newCat.children = [Category]()
            for aDic in subCats {
                let newLevel = level + 1
                if let aChild = Category.instance(from: aDic, level: newLevel) {
                    newCat.children?.append(aChild)
                    aChild.parent = newCat
                }
            }
        }
        
        return newCat
    }

}

fileprivate var tempContainer = [Category]()
