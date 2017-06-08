//
//  CommentListTableViewController.swift
//  Kuriozumok
//
//  Created by Kiss Rudolf Zsolt on 2015. 12. 14..
//  Copyright © 2015. Kiss Rudolf Zsolt. All rights reserved.
//

import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class CommentListTableViewController: UITableViewController {
    
    var nameCardSelected: NameCard!

    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if self.nameCardSelected.comments?.count < 1 {
            let title = NSLocalizedString("No comments found for this curioso yet.", comment: "Alert title when no comments found.")
            let message = NSLocalizedString("Be the first who is commenting this. Tap on the add button on top right corner.", comment: "Alert view message when no comments found.")
            
            KuriozumokUtil.displayAlert(message, title: title, delegate: nil)

        }
    }

    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if self.nameCardSelected.comments == nil {
            return 0
        } else {
            return self.nameCardSelected.comments!.count
        }
        
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)

        if let cc = cell as? CommentCell {
            let aComment = self.nameCardSelected.comments![indexPath.row]
            cc.customizeWithComment(aComment)
        }

        return cell
    }
    

    

    
    

    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddCommentSegue" {
            if let nextVC = segue.destination as? AddCommentViewController {
                nextVC.nameCardId = self.nameCardSelected.nameCardId
                nextVC.nameCardName = self.nameCardSelected.name
            }
        }
    }
    

}
