//
//  CategoryCell.swift
//  Kuriozumok
//
//  Created by Kiss Rudolf Zsolt on 2017. 07. 11..
//  Copyright © 2017. Kiss Rudolf Zsolt. All rights reserved.
//

import UIKit

class CategoryCell: UITableViewCell {
    
    
    @IBOutlet weak var lbCategoryName: UILabel!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lbCategoryName.textColor = UIColor.white
        backgroundColor = KuriozumokUtil.applicationColors()[2]
        
        selectionStyle = UITableViewCellSelectionStyle.none
    }
    
    func update(with category: Category) {
        lbCategoryName.text = category.title
        leadingConstraint.constant = CGFloat(category.level) * CGFloat(20)
        
        if category.isSelected {
            accessoryType = UITableViewCellAccessoryType.checkmark
        } else {
            accessoryType = UITableViewCellAccessoryType.none
        }
    }
    
}
