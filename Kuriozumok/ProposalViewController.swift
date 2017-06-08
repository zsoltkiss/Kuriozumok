//
//  ProposalViewController.swift
//  Kuriozumok
//
//  Created by Kiss Rudolf Zsolt on 2015. 12. 09..
//  Copyright © 2015. Kiss Rudolf Zsolt. All rights reserved.
//

import UIKit
import CoreLocation
import MobileCoreServices
import Alamofire

class ProposalViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    
    @IBOutlet weak var tfName: UITextField!
    @IBOutlet weak var tvDescription: UITextView!
    @IBOutlet weak var lbGeocodeAddress: UILabel!
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var btnAddPicture1: UIButton!
    @IBOutlet weak var btnAddPicture2: UIButton!
    
    fileprivate var locationManager: CLLocationManager!
    fileprivate var geocoder: CLGeocoder!
    fileprivate var placemark: CLPlacemark?
    
    fileprivate var gpsLocationOfCurio: CLLocation?
    
    fileprivate var postDataTown: String = ""
    fileprivate var postDataAddress: String = ""
    
    fileprivate var descriptionFieldShouldClear = true
    
    fileprivate weak var targetImageView: UIImageView?
    
    fileprivate var imageImported1: UIImage?
    fileprivate var imageImported2: UIImage?
    
    fileprivate var imageDate1: Date?
    fileprivate var imageDate2: Date?

    
    fileprivate var activityIndicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager = CLLocationManager()
        self.geocoder = CLGeocoder()
        
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.requestWhenInUseAuthorization()
        
        self.tvDescription.text = NSLocalizedString("Optionally you can write few words here about this curio", comment: "Placeholder text in text view.")
        btnAddPicture1.setTitle(NSLocalizedString("Picture 1", comment: "Button title for picture 1."), for: .normal)
        btnAddPicture2.setTitle(NSLocalizedString("Picture 2", comment: "Button title for picture 2."), for: .normal)
    }
    
    
    // MARK: - Action handling
    @IBAction func addImageTapped(_ sender: UIButton) {
        targetImageView = sender == btnAddPicture1 ? imageView1 : imageView2
        displayImageSelectionPrompt()
    }

    @IBAction func sendButtonTapped(_ sender: UIButton) {
        
        if self.gpsLocationOfCurio == nil {
            
            let title = NSLocalizedString("Missing location", comment: "Alert controller title when device location is unknown before sending proposal")
            let message = NSLocalizedString("You won't be able to send proposal without known GPS location of your device.", comment: "Alert controller message when GPS location is unknown")
            
            let controller = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
            
            let button1Title = NSLocalizedString("Turn GPS on", comment: "Button title on action controller")
            let gpsOnAction = UIAlertAction(title: button1Title, style: UIAlertActionStyle.default, handler: { (someAction) -> Void in
                print("User wants to enable GPS...")
            })
            
            let button2Title = NSLocalizedString("Cancel", comment: "Button title on action controller")
            let cancelAction = UIAlertAction(title: button2Title, style: UIAlertActionStyle.default, handler: { (someAction) -> Void in
                print("User rejected to turn GPS on")
            })
            
            controller.addAction(gpsOnAction)
            controller.addAction(cancelAction)
            
            self.present(controller, animated: true, completion: nil)
            
        } else {
            if self.tfName.text!.isEmpty {
                
                let title = NSLocalizedString("Missing input", comment: "Alert view title when form validation failed")
                let message = NSLocalizedString("Name field must not be empty", comment: "Alert view message when form validation failed")
                
                KuriozumokUtil.displayAlert(message, title: title, delegate: nil)
            } else {
                if self.activityIndicator == nil {
                    self.activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
                    self.activityIndicator?.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
                    self.activityIndicator?.hidesWhenStopped = true
                    self.activityIndicator?.backgroundColor = UIColor.white
                    self.activityIndicator?.alpha = 0.5
                    
                    self.view.addSubview(self.activityIndicator!)
                }
                
                self.activityIndicator?.startAnimating()
                self.uploadWithAlamo()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func displayImageSelectionPrompt() {
        
        let controllerTitle = NSLocalizedString("Choose an image source", comment: "Alert controller title")
        let controllerMessage = NSLocalizedString("You could import an image from your photo library or just take a picture now.", comment: "Alert controller message")
        
        let importActionTitle = NSLocalizedString("Import from photo library", comment: "Button title on alert controller")
        let takeActionTitle = NSLocalizedString("Take a picture", comment: "Button title on alert controller")
        let cancelActionTitle = NSLocalizedString("Cancel", comment: "Button title on alert controller")
        
        let actionImport = UIAlertAction(title: importActionTitle, style: UIAlertActionStyle.default) { (alertAction) -> Void in
            self.displayImagePickerUsingSourceType(UIImagePickerControllerSourceType.photoLibrary)
        }
        
        let actionTake = UIAlertAction(title: takeActionTitle, style: UIAlertActionStyle.default) { (alertAction) -> Void in
            self.displayImagePickerUsingSourceType(UIImagePickerControllerSourceType.camera)
        }
        
        let actionCancel = UIAlertAction(title: cancelActionTitle, style: UIAlertActionStyle.cancel) { (alertAction) -> Void in
            self.dismiss(animated: true, completion: nil)
        }
        
        let controller = UIAlertController(title: controllerTitle, message: controllerMessage, preferredStyle: UIAlertControllerStyle.actionSheet)
        controller.addAction(actionImport)
        controller.addAction(actionTake)
        controller.addAction(actionCancel)
        
        self.present(controller, animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    // MARK: - UIImagePickerControllerDelegate protocol
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        print("Image imported: \(image)")
        print("editingInfo: \(String(describing: editingInfo))")
        
        let now = Date()
        
        if self.targetImageView == self.imageView1 {
            self.imageImported1 = image
            self.imageDate1 = now
        } else if self.targetImageView == self.imageView2 {
            self.imageImported2 = image
            self.imageDate2 = now

        }
        
        self.targetImageView?.image = image
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("!!! YEP !!!")
        self.targetImageView = nil
        
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITextFieldDelegate methods
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    
    // MARK: - UITextViewDelegate
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if self.descriptionFieldShouldClear {
            self.tvDescription.text = ""
            self.descriptionFieldShouldClear = false
        }
        
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        self.view.endEditing(true)
        return true
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Fetching current location failed.")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("\(#function) called")
        
        if let newLocation = locations.last {
            self.locationManager.stopUpdatingLocation()
            
            (UIApplication.shared.delegate as! AppDelegate).deviceLocation = newLocation
            self.gpsLocationOfCurio = newLocation
            self.lbGeocodeAddress.text = "\(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)"
            
            
            // Reverse Geocoding
            self.geocoder.reverseGeocodeLocation(newLocation, completionHandler: { (placemarks, error) -> Void in
                if error != nil {
                    print("Reverse geocoding failed? \(error!)")
                }
                
                if placemarks != nil && placemarks!.count > 0 {
                    if let aPlacemark = placemarks!.last {
                        self.placemark = aPlacemark
                        
                        print("Placemark found: \(aPlacemark)")
                        
                        var locationText = ""
                        
                        if self.placemark!.locality != nil {
                            locationText += (self.placemark?.locality)!
                        }
                        
                        if self.placemark!.country != nil {
                            locationText += ", \(self.placemark!.country!)"
                        }
                        
                        
                        if self.placemark?.postalCode != nil {
                            self.postDataTown += "\(self.placemark!.postalCode!)"
                        }
                        
                        if self.placemark?.locality != nil {
                            self.postDataTown += " \(self.placemark!.locality!)"
                        }
                        
                        
                        if self.placemark?.thoroughfare != nil {
                            self.postDataAddress += "\(self.placemark!.thoroughfare!)"
                        }
                        
                        if self.placemark?.subThoroughfare != nil {
                            self.postDataAddress += " \(self.placemark!.subThoroughfare!)"
                        }
                        
                        // street number
                        print("subThoroughfare: \(String(describing: self.placemark?.subThoroughfare))\n")
                        
                        // street
                        print("thoroughfare: \(String(describing: self.placemark?.thoroughfare))\n")
                        
                        // ZIP code
                        print("postalCode: \(String(describing: self.placemark?.postalCode))\n")
                        
                        // county or city??
                        print("administrativeArea: \(String(describing: self.placemark?.administrativeArea))\n")
                        
                        // city/town
                        print("locality: \(String(describing: self.placemark?.locality))\n")
                        print("country: \(String(describing: self.placemark?.country))\n")
                        
                        self.lbGeocodeAddress.text = locationText
                    }
                }
            })
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        var shouldIAllow = false
        
        switch status {
        case CLAuthorizationStatus.restricted:
            print("Restricted Access to location")
        case CLAuthorizationStatus.denied:
            print("User denied access to location")
        case CLAuthorizationStatus.notDetermined:
            print("Status not determined")
        default:
            print("Allowed to location Access")
            shouldIAllow = true
        }
        
        if (shouldIAllow == true) {
            locationManager.startUpdatingLocation()
        }
    }

    // MARK: - Private methods
    fileprivate func displayImagePickerUsingSourceType(_ sourceTypeSelectedByUser: UIImagePickerControllerSourceType) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = false
        imagePickerController.sourceType = sourceTypeSelectedByUser
        imagePickerController.mediaTypes = [kUTTypeImage as String]
        
        if sourceTypeSelectedByUser == .camera && UIImagePickerController.isSourceTypeAvailable(.camera) == false {
            imagePickerController.sourceType = .photoLibrary
        }
        
        self.present(imagePickerController, animated: true, completion: nil)

    }
    
    fileprivate func uploadWithAlamo() {
        print("\(#function) called")
        
        Alamofire.upload(multipartFormData: { multipartFormData in
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd_HHmmss"
            
            if self.imageImported1 != nil {
                let fileExtension = ".jpg"  //".png"
                let mimeType = "image/jpg"             // "image/png"
                
                let fileNameFromImportDate = formatter.string(from: self.imageDate1!) + fileExtension
                
                let imageData = UIImageJPEGRepresentation(self.imageImported1!, 0.8);
                //The float param (0.8 in this example) is the compression quality
                //expressed as a value from 0.0 to 1.0, where 1.0 represents
                //the least compression (or best quality).
                
                multipartFormData.append(imageData!, withName: "photo1", fileName: fileNameFromImportDate, mimeType: mimeType)
                print("PHOTO1 added to multipart form data: \(fileNameFromImportDate)")
            }
            
            if self.imageImported2 != nil {
                let mimeType = "image/png"
                let fileNameFromImportDate = formatter.string(from: self.imageDate2!) + ".png"
                let imageData = UIImagePNGRepresentation(self.imageImported2!)
                multipartFormData.append(imageData!, withName: "photo2", fileName: fileNameFromImportDate, mimeType: mimeType)
                print("PHOTO2 added to multipart form data: \(fileNameFromImportDate)")
            }
            
            if let title = self.tfName.text, let titleData = title.data(using: String.Encoding.utf8) {
                multipartFormData.append(titleData, withName: "title")
                print("TITLE added to multipart form data: \(self.tfName.text!)")
            }
            
            if let latitudeData = "\(self.gpsLocationOfCurio!.coordinate.latitude)".data(using: String.Encoding.utf8) {
                multipartFormData.append(latitudeData, withName: "latitude")
                print("LATITUDE added to multipart form data: \(self.gpsLocationOfCurio!.coordinate.latitude)")

            }
            
            if let longitudeData = "\(self.gpsLocationOfCurio!.coordinate.longitude)".data(using: String.Encoding.utf8) {
                multipartFormData.append(longitudeData, withName: "longitude")
                print("LONGITUDE added to multipart form data: \(self.gpsLocationOfCurio!.coordinate.longitude)")
            }
            
            
            if self.postDataTown.isEmpty == false {
                if let townData = self.postDataTown.data(using: String.Encoding.utf8) {
                    multipartFormData.append(townData, withName: "town")
                    print("TOWN added to multipart form data: \(self.postDataTown)")
                }
            }
        
            if self.postDataAddress.isEmpty == false {
                if let addressData = self.postDataAddress.data(using: String.Encoding.utf8) {
                    multipartFormData.append(addressData, withName: "address")
                    print("ADDRESS added to multipart form data: \(self.postDataAddress)")
                }
            }
            
            
            if self.tvDescription.text!.isEmpty == false {
                if let descriptionData = self.tvDescription.text.data(using: String.Encoding.utf8) {
                    multipartFormData.append(descriptionData, withName: "description")
                    print("DESCRIPTION added to multipart form data: \(self.tvDescription.text!)")
                }
            }
            
        }, to: REQUEST_URL_PROPOSAL) { (encodingResult) -> Void  in
            print("Result of Alamofire upload: \(encodingResult)\n----------------------\n")
            
            switch encodingResult {
            case .success(let upload, _, _):
                print("Result: .success")
                
                upload.responseData(completionHandler: { (response) in
                    //todo
                    print("in completion handler, res: \(response)")
                })
                
            case .failure(let encodingError):
                print("Result: .failure")
                print(encodingError)
            }
            
            
            self.activityIndicator?.stopAnimating()
            
            self.imageImported1 = nil
            self.imageImported2 = nil
            
            let placeholderImage = UIImage(named: "image_placeholder")
            self.imageView1.image = placeholderImage
            self.imageView2.image = placeholderImage
            
            self.tfName.text = ""
            self.tvDescription.text = ""
            
            self.navigationController?.popViewController(animated: true)

        }
    }
}
