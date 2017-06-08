//
//  NameCardDetailsViewController.swift
//  Kuriozumok
//
//  Created by Kiss Rudolf Zsolt on 2015. 11. 24..
//  Copyright © 2015. Kiss Rudolf Zsolt. All rights reserved.
//

import UIKit
import Kingfisher

let IMAGE_CACHE_KEY = "namecard_image_"

class NameCardDetailsViewController: UIViewController {
    
    @IBOutlet weak var lbName: UILabel!
    @IBOutlet weak var lbAddress: UILabel!
    @IBOutlet weak var lbPhone: UILabel!
    @IBOutlet weak var lbCellular: UILabel!
    @IBOutlet weak var lbEmail: UILabel!
    @IBOutlet weak var lbWeb: UILabel!
    @IBOutlet weak var scrollViewForImages: UIScrollView!
    @IBOutlet weak var lbDescription: UILabel!
    @IBOutlet weak var btnRoute: UIButton!
    
    var selectedNameCard: NameCard!
    
    //fileprivate var images = Dictionary<Int, UIImage>()
    fileprivate let gap = CGFloat(20.0)
    fileprivate let startTagForImages = 100
    fileprivate var pagerStartIndex = -1
    
    lazy var images: [UIImage] = {
        var arrayOfDownloadedImages = [UIImage]()
        
        for i in 0 ..< self.scrollViewForImages.subviews.count {
            ImageCache.default.retrieveImage(forKey: IMAGE_CACHE_KEY + "\(i)", options: nil, completionHandler: { (image, cacheType) in
                if let anImage = image {
                    arrayOfDownloadedImages.append(anImage)
                }
            })
        }
        
        return arrayOfDownloadedImages
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.lbName.text = selectedNameCard.name
        self.lbAddress.text = selectedNameCard.address
        self.lbPhone.text = selectedNameCard.phone
        self.lbCellular.text = selectedNameCard.cellPhone
        self.lbEmail.text = selectedNameCard.email
        self.lbWeb.text = selectedNameCard.webPage
        
        self.lbDescription.text = selectedNameCard.cardDescription
        
        if self.selectedNameCard.imageUrls != nil {
            let arrayLength = self.selectedNameCard.imageUrls!.count
            
            let imageWidth = self.scrollViewForImages.frame.size.height
            let fullWidth = (gap + imageWidth) * CGFloat(arrayLength)
            
            self.scrollViewForImages.contentSize = CGSize(width: fullWidth, height: self.scrollViewForImages.frame.size.height)
            
            for i in 0..<arrayLength {
                addImageToScrollview(at: i, imageUrl: URL(string: BASE_URL + self.selectedNameCard.imageUrls![i])!)
            }
        }
        
        let buttonTitle = NSLocalizedString("Plannig route", comment: "Title of route planning button")
        self.btnRoute.setTitle(buttonTitle, for: UIControlState())
    }
    
    func showImagePager(_ rec: UITapGestureRecognizer) {
        if let imageViewTapped = rec.view as? UIImageView {
            self.pagerStartIndex = imageViewTapped.tag - self.startTagForImages
            
            print("image tapped at postion \(self.pagerStartIndex)")
            
            self.performSegue(withIdentifier: "ShowImagePagerSegue", sender: imageViewTapped)
        }
    }
    
    private func addImageToScrollview(at position: Int, imageUrl: URL) {
        let imageWidth = CGFloat(90.0)
        let imageHeight = imageWidth
        
        let startX = CGFloat(position) * (imageWidth + gap)
        
        print("position: \(position), startX: \(startX)")
        
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        
        imageView.tag = startTagForImages + position
        imageView.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(NameCardDetailsViewController.showImagePager(_:)))
        imageView.addGestureRecognizer(gesture)
        
        let widthC = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: imageWidth)
        let heightC = NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: imageHeight)
        
        let centerY = NSLayoutConstraint(item: imageView, attribute: .centerY, relatedBy: .equal, toItem: self.scrollViewForImages, attribute: .centerY, multiplier: 1.0, constant: 0.0)
        let leadingSpace = NSLayoutConstraint(item: imageView, attribute: .leading, relatedBy: .equal, toItem: self.scrollViewForImages, attribute: .leadingMargin, multiplier: 1.0, constant: startX)
        
        self.scrollViewForImages.addSubview(imageView)
        
        imageView.addConstraint(widthC)
        imageView.addConstraint(heightC)
        
        self.scrollViewForImages.addConstraint(centerY)
        self.scrollViewForImages.addConstraint(leadingSpace)
        
        imageView.kf.setImage(with: imageUrl, completionHandler: { (image, error, cacheType, imageUrl) in

            if error != nil {
                print("Error occured when tried to download image from \(String(describing: imageUrl!))")
            }
            
            if image != nil {
                ImageCache.default.store(image!, forKey: IMAGE_CACHE_KEY + "\(position)")
                print("Image successfully downloaded and set at position \(position)")
            }
            
            // image: Image? `nil` means failed
            // error: NSError? non-`nil` means failed
            // cacheType: CacheType
            //                  .none - Just downloaded
            //                  .memory - Got from memory cache
            //                  .disk - Got from disk cache
            // imageUrl: URL of the image
        })
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowCommentsSegue" {
            if let nextVC = segue.destination as? CommentListTableViewController {
                nextVC.nameCardSelected = self.selectedNameCard
            }
        } else if segue.identifier == "ShowImagePagerSegue" {
            if let popup = segue.destination as? ImagePagerViewController {
                popup.images = self.images
                popup.currentIndex = self.pagerStartIndex
                self.view.alpha = 0.6
                popup.providesPresentationContextTransitionStyle = true;
                popup.definesPresentationContext = true;
                popup.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            }
        }
        
    }
    
    // MARK: - Action handling
    
    @IBAction func openMapApplication(_ sender: UIButton) {
        if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
            UIApplication.shared.open(URL(string:
                "comgooglemaps://?saddr=&daddr=\(self.selectedNameCard.latitude),\(self.selectedNameCard.longitude)&directionsmode=driving")!, options: [:], completionHandler: nil)
            
        } else {
            let msgTitle = NSLocalizedString("Can't launch app", comment:"Alert view title when route planning is not possible")
            let msgText = NSLocalizedString("Google Maps application needed on your device", comment:"Alert view text when route planning is not possible")
            KuriozumokUtil.displayAlert(msgText, title: msgTitle, delegate: nil)
        }
    
        

    }
    
    // MARK: - Private methods
    class func displayCustomInfoMessage(from messageOwner: UIViewController) {
        let popup = ImagePagerViewController()

        messageOwner.view.alpha = 0.6
        
        popup.providesPresentationContextTransitionStyle = true
        popup.definesPresentationContext = true
        popup.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        
        
        messageOwner.present(popup, animated: true) { () -> Void in
            
        }
    }

    
    

}
