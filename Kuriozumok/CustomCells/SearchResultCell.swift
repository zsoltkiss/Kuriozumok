//
//  SearchResultCell.swift
//  Kuriozumok
//
//  Created by Kiss Rudolf Zsolt on 2015. 11. 24..
//  Copyright © 2015. Kiss Rudolf Zsolt. All rights reserved.
//

import UIKit

class SearchResultCell: UITableViewCell {
    
    
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbAddress: UILabel!
    @IBOutlet weak var lbPhone: UILabel!
    @IBOutlet weak var lbCategory: UILabel!
    @IBOutlet weak var lbDistance: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    func customize(withNameCard nameCard: NameCard) {
        self.lbName.text = nameCard.name
        self.lbAddress.text = nameCard.address
        self.lbPhone.text = nameCard.cellPhone ?? nameCard.phone ?? ""
        self.lbCategory.text = nameCard.category?.title
        
        let doubleValue = nameCard.distanceFromLocationInMeters((UIApplication.shared.delegate as! AppDelegate).deviceLocation) / 1000.0
        let roundedValue = Int(doubleValue)
        
        self.lbDistance.text = "\(roundedValue) km"
    }

}
