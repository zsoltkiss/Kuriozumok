//
//  AddCommentViewController.swift
//  Kuriozumok
//
//  Created by Kiss Rudolf Zsolt on 2015. 12. 14..
//  Copyright © 2015. Kiss Rudolf Zsolt. All rights reserved.
//

import UIKit
import RxSwift
import RxAlamofire
import SnapKit


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

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

class AddCommentViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var tfAuthorName: UITextField!
    @IBOutlet weak var tvComment: UITextView!
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var webView: UIWebView!

    var nameCardId: Int!
    var nameCardName: String!
    
    private var disposeBag = DisposeBag()
    
    fileprivate var textViewShouldBeCleared = true
    
    private weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let indicator = UIActivityIndicatorView()
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        indicator.hidesWhenStopped = true
        indicator.backgroundColor = UIColor.clear
        self.view.addSubview(indicator)
        
        self.activityIndicator = indicator
        
        indicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        self.tvComment.text = NSLocalizedString("We are wondering what's your opinion.", comment: "Initial text view content when adding a comment.")
        self.lbName.text = self.nameCardName
        
        
        //https://www.youtube.com/watch?v=7lLrj3vcveQ
        
        loadYoutube(videoID: "7lLrj3vcveQ")
    }

    @IBAction func sendButtonTapped(_ sender: UIButton) {
        if self.validateInput() {
            if let author = self.tfAuthorName.text, let comment = self.tvComment.text, let ncId = self.nameCardId {
                self.activityIndicator.startAnimating()
                json(.post, REQUEST_URL_COMMENT, parameters: ["id": ncId, "author": author, "text": comment])
                    .subscribe(onNext: { [weak self] in
                        print("Response to 'add comment' request: \($0)")
                        
                        self?.activityIndicator.stopAnimating()
                        
                        if let nc = self?.presentingViewController as? UINavigationController {
                            nc.popToRootViewController(animated: true)
                        }
                        
                        self?.dismiss(animated: true, completion: nil)
                        
                    }, onError: { [weak self] error in
                        print("ERROR in response: \(error))")
                        self?.displayServerError()
                    })
                    .addDisposableTo(disposeBag)
            }
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        if let nc = self.presentingViewController as? UINavigationController {
            let index = nc.viewControllers.count - 2
            let detailsVC = nc.viewControllers[index]
            
            nc.popToViewController(detailsVC, animated: true)
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    // MARK:  UITextViewDelegate methods
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if self.textViewShouldBeCleared {
            // removing user info message fro text view
            self.tvComment.text = ""
            
            self.textViewShouldBeCleared = false
        }
        
        return true
    }
    
    // MARK: - Private methods
    fileprivate func validateInput() -> Bool {
        if self.tvComment.text.isEmpty || self.textViewShouldBeCleared {
            let message = NSLocalizedString("Comment text must not be empty.", comment: "User input validation error message on alert view")
            let title = NSLocalizedString("Missing or invalid input", comment: "User input validation error title on alert view")
            KuriozumokUtil.displayAlert(message, title: title, delegate: nil)
            
            return false
        }
        
        return true
    }
    
    fileprivate func displayServerError() {
        self.activityIndicator.stopAnimating()
        let connectionError = NSLocalizedString("Sending your comment failed.", comment:"Comment sending error message on alert view")
        let title = NSLocalizedString("Error", comment:"Error message alert view title")
        
        KuriozumokUtil.displayAlert(connectionError, title: title, delegate: nil)
        
    }
    
    
    private func loadYoutube(videoID:String) {
        guard
            let youtubeURL = URL(string: "https://www.youtube.com/embed/\(videoID)")
            else { return }
        webView.loadRequest( URLRequest(url: youtubeURL) )
    }
}

extension AddCommentViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        
        return true
    }
}
