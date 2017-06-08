//
//  NameCardPinAnnotationView.swift
//  Kuriozumok
//
//  Created by Kiss Rudolf Zsolt on 2016. 01. 07..
//  Copyright © 2016. Kiss Rudolf Zsolt. All rights reserved.
//

import UIKit
import MapKit

class NameCardPinAnnotationView: MKPinAnnotationView {
    
    var nameCard: NameCard?

//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        print("!!! init:frame >> annotation: \(self.annotation), nameCard: \(self.nameCard)")
//        
////        fatalError("init(frame:) has not been implemented")
//    }
    
    init(aCard: NameCard, reuseId: String) {
        self.nameCard = aCard
        super.init(annotation: aCard, reuseIdentifier: reuseId)
        self.annotation = aCard
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

}
