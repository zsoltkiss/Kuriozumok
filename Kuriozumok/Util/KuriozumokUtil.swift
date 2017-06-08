//
//  KuriozumokUtil.swift
//  Kuriozumok
//
//  Created by Kiss Rudolf Zsolt on 2015. 11. 20..
//  Copyright © 2015. Kiss Rudolf Zsolt. All rights reserved.
//

import UIKit

class KuriozumokUtil: NSObject {
    
    
    // Predefined colors in the design (szinpaletta.jpg)
    class func applicationColors() -> [UIColor] {
        
        var appColors = Array<UIColor>()
        
        // #162b42 >> 22 43 66
        appColors.append(UIColor(red: 22.0/255.0, green: 43.0/255.0, blue: 66.0/255.0, alpha: 1.0))
        
        // #283d54 >> 40 61 84
        appColors.append(UIColor(red: 40.0/255.0, green: 61.0/255.0, blue: 84.0/255.0, alpha: 1.0))
        
        // #91b7e9 >> 141 183 233
        appColors.append(UIColor(red: 141.0/255.0, green: 183.0/255.0, blue: 233.0/255.0, alpha: 1.0))
        
        // #222222 >> 34 34 34
        appColors.append(UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0))
        
        // #b2b3b5 >> 178 179 181
        appColors.append(UIColor(red: 178.0/255.0, green: 179.0/255.0, blue: 181.0/255.0, alpha: 1.0))
        
        // #d7dadd >> 215 218 221
        appColors.append(UIColor(red: 215.0/255.0, green: 218.0/255.0, blue: 221.0/255.0, alpha: 1.0))
        
        // #ededed >> 237 237 237
        appColors.append(UIColor(red: 237.0/255.0, green: 237.0/255.0, blue: 237.0/255.0, alpha: 1.0))
        
        // #ffffff
        appColors.append(UIColor.white)
    
        return appColors
    
    }
    
    class func displayAlert(_ message: String?, title: String, delegate: UIAlertViewDelegate?) {
        let av = UIAlertView(title: title, message: message, delegate: delegate, cancelButtonTitle: "OK")
        av.show()
    }
    
    
    /**
     http://stackoverflow.com/questions/4147311/finding-image-type-from-nsdata-or-uiimage
    */
    class func metadataForImage(_ imageData: Data ) -> Dictionary<String, String?> {
        var c: UInt8!
        
        var meta = Dictionary<String, String?>()
        
        (imageData as NSData).getBytes(&c, length: 1)
        
        switch (c) {
        case 0xFF:
            meta["mimeType"] = "image/jpeg"
            meta["extension"] = ".jpg"
        case 0x89:
            meta["mimeType"] = "image/png"
            meta["extension"] = ".png"
        case 0x47:
            meta["mimeType"] = "image/gif"
            meta["extension"] = ".gif"
        case 0x4D:
            meta["mimeType"] = "image/tiff"
            meta["extension"] = ".tif"
        default: break
            
        }
        
        return meta

    }
    
   
}
