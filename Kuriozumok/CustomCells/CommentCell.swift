//
//  CommentCell.swift
//  Kuriozumok
//
//  Created by Kiss Rudolf Zsolt on 2015. 12. 14..
//  Copyright © 2015. Kiss Rudolf Zsolt. All rights reserved.
//

import UIKit

class CommentCell: UITableViewCell {

    @IBOutlet weak var lbAuthor: UILabel!
    @IBOutlet weak var lbDate: UILabel!
    @IBOutlet weak var lbComment: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        self.selectionStyle = UITableViewCellSelectionStyle.none

        // Configure the view for the selected state
    }
    
    func customizeWithComment(_ someComment: Comment) {
        self.lbAuthor.text = "Anonymous"
        
        if someComment.author != nil && someComment.author!.isEmpty == false {
            self.lbAuthor.text = someComment.author
        }
        
        self.lbDate.text = someComment.commentDateFormatted()
        self.lbComment.text = someComment.text
    }

}
