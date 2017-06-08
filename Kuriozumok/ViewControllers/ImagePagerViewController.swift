//
//  ImagePagerViewController.swift
//  Kuriozumok
//
//  Created by Kiss Rudolf Zsolt on 2016. 01. 21..
//  Copyright © 2016. Kiss Rudolf Zsolt. All rights reserved.
//

import UIKit

class ImagePagerViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var images: [UIImage?]!
    
    var currentIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageView.image = self.images[self.currentIndex]
    
    }
    
    // MARK: - Action handling

    @IBAction func closeButtonTapped(_ sender: UIButton) {
        if let previousVC = self.getPresenterViewController() {
            previousVC.view.alpha = 1.0
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func imageTapped(_ sender: UITapGestureRecognizer) {
        
        if self.currentIndex == self.images.count - 1 {
            self.currentIndex = 0
        } else {
            self.currentIndex += 1
        }
        
        print("currentIndex: \(self.currentIndex), elements in the array: \(self.images.count)")
        
        self.imageView.image = self.images[self.currentIndex]
    }
    
    // MARK: - Private methods
    // MARK: - Private methods
    fileprivate func getPresenterViewController() -> UIViewController? {
        if let navController = self.presentingViewController as? UINavigationController {
            let previousVC = navController.viewControllers[navController.viewControllers.count - 1]
            return previousVC
        }
        
        return nil
    }
}
