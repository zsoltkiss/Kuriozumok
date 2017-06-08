//
//  Comment.swift
//  Kuriozumok
//
//  Created by Kiss Rudolf Zsolt on 2015. 11. 24..
//  Copyright © 2015. Kiss Rudolf Zsolt. All rights reserved.
//

import UIKit

/**
 Example of server data:
 
 (
 {
 author = Mobile;
 content = "Nagyon nagyon j\U00f3 a c\U00e9g";
 date = "2015-12-06T11:46:22+0100";
 }
 )

*/


let PARSE_COMMENT_DATE_FORMAT = "yyyy-MM-dd'T'HH:mm:ssZ"
let UI_COMMENT_DATE_FORMAT = "yyyy.MM.dd. HH:mm:ss"

class Comment: NSObject {
    
    
    var author: String?
    var date: Date?
    var text: String!
    weak var  nameCard: NameCard?
    
    init(dictionary: Dictionary<String, AnyObject>) {
        if let author = dictionary["author"] as? String {
            self.author = author
        }
        
        self.text = dictionary["content"] as! String
        
        if let strDate = dictionary["date"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = PARSE_COMMENT_DATE_FORMAT
            
            self.date = formatter.date(from: strDate)
        }
    }
    
    func commentDateFormatted() -> String? {
        if self.date != nil {
            
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = UI_COMMENT_DATE_FORMAT
            
            return outputFormatter.string(from: self.date!)
        }
        
        return nil
    }

}
