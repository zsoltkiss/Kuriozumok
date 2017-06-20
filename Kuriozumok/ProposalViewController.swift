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
import RxSwift
import RxAlamofire
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
    
    fileprivate var descriptionFieldShouldClear = true
    
    fileprivate weak var targetImageView: UIImageView?
    
    fileprivate var imageImported1: UIImage?
    fileprivate var imageImported2: UIImage?
    
    fileprivate var imageDate1: Date?
    fileprivate var imageDate2: Date?

    private var disposeBag = DisposeBag()
    fileprivate var activityIndicator: UIActivityIndicatorView?
    
    private var locationText: String? {
        guard let aPlacemark = self.placemark else {
            return nil
        }
        
        let city = aPlacemark.locality ?? ""
        let country = aPlacemark.country ?? ""
        
        if !city.isEmpty && !country.isEmpty {
            return "\(city), \(country)"
        } else {
            return city.isEmpty ? country : city
        }
    }
    
    private var postParams: [String:Any] {
        var params = [String: Any]()
        
        if let title = self.tfName.text {
            params["title"] = title
        }
        
        if let desc = self.tvDescription.text {
            if !desc.isEmpty {
                params["description"] = desc
            }
        }
        
        if let latDegrees = self.gpsLocationOfCurio?.coordinate.latitude {
            params["latitude"] = "\(latDegrees)"
        }
        
        if let lonDegrees = self.gpsLocationOfCurio?.coordinate.longitude {
            params["longitude"] = "\(lonDegrees)"
        }
        
        if let zip = placemark?.postalCode {
            params["postalCode"] = zip
        }
        
        if let town = placemark?.locality {
            params["town"] = town
        }
        
        if let street = placemark?.thoroughfare {
            params["street"] = street
        }
        
        if let houseNumber = placemark?.subThoroughfare {
            params["houseNumber"] = houseNumber
        }
        
        return params
    }

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
                        self.placemarkInfo(aPlacemark)
                        self.lbGeocodeAddress.text = self.locationText
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
            let params = self.postParams
            
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
            
            if let title = params["title"] as? String, let titleData = title.data(using: String.Encoding.utf8) {
                multipartFormData.append(titleData, withName: "title")
                print("TITLE added to multipart form data: \(title)")
            }
            
            if let description = params["description"] as? String, let descriptionData = description.data(using: String.Encoding.utf8) {
                multipartFormData.append(descriptionData, withName: "description")
                print("DESCRIPTION added to multipart form data: \(description)")
            }
            
            if let latitude = params["latitude"] as? String, let latitudeData = latitude.data(using: String.Encoding.utf8) {
                multipartFormData.append(latitudeData, withName: "latitude")
                print("LATITUDE added to multipart form data: \(latitude)")
            }
            
            if let longitude = params["longitude"] as? String, let longitudeData = longitude.data(using: String.Encoding.utf8) {
                multipartFormData.append(longitudeData, withName: "longitude")
                print("LONGITUDE added to multipart form data: \(longitude)")
            }
            
            if let postalCode = params["postalCode"] as? String, let postalCodeData = postalCode.data (using: String.Encoding.utf8) {
                multipartFormData.append(postalCodeData, withName: "postalCode")
                print("POSTAL CODE added to multipart form data: \(postalCode)")
            }
            
            if let town = params["town"] as? String, let townData = town.data(using: String.Encoding.utf8) {
                multipartFormData.append(townData, withName: "town")
                print("TOWN added to multipart form data: \(town)")
            }
            
            if let street = params["street"] as? String, let streetData = street.data(using: String.Encoding.utf8) {
                multipartFormData.append(streetData, withName: "street")
                print("STREET added to multipart form data: \(street)")
            }
            
            if let houseNumber = params["houseNumber"] as? String, let houseNumberData = houseNumber.data(using: String.Encoding.utf8) {
                multipartFormData.append(houseNumberData, withName: "houseNumber")
                print("HOUSE NUMBER added to multipart form data: \(houseNumber)")
            }
            
        }, to: REQUEST_URL_PROPOSAL) { (encodingResult) -> Void  in
            print("Result of Alamofire upload: \(encodingResult)\n----------------------\n")
            
            switch encodingResult {
            case .success(let upload, _, _):
                print("Result: .success")
                
                print("----------------\n\n")
                
                
//                upload.responseJSON { response in
//                    print("JSON resposne: \(response)")
//                    
//                    self.activityIndicator?.stopAnimating()
//                }
                
                upload.responseString { response in
                    debugPrint("String response: \(response)")
                    
                    self.activityIndicator?.stopAnimating()
                    
                    self.imageImported1 = nil
                    self.imageImported2 = nil
                    
                    self.imageView1.image = nil
                    self.imageView2.image = nil
                    
                    self.tfName.text = ""
                    self.tvDescription.text = ""
                    
                    self.navigationController?.popViewController(animated: true)

                }
                
//                upload.responseData(completionHandler: { (response) in
//                    debugPrint("Data response: \(response)")
//                    
//                    self.activityIndicator?.stopAnimating()
//                })
                
            case .failure(let encodingError):
                print("Result: .failure")
                print(encodingError)
                self.activityIndicator?.stopAnimating()
            }
        }
    }

    private func placemarkInfo(_ aPlacemark: CLPlacemark) {
        print("Placemark found: \(aPlacemark)")
        
        // country
        print("country: \(String(describing: aPlacemark.country))\n")
        
        // megye
        print("administrativeArea: \(String(describing: aPlacemark.administrativeArea))\n")
        
        // ZIP code
        print("postalCode: \(String(describing: aPlacemark.postalCode))\n")
        
        // city/town
        print("locality: \(String(describing: aPlacemark.locality))\n")
        
        // street
        print("thoroughfare: \(String(describing: aPlacemark.thoroughfare))\n")
        
        // street number
        print("subThoroughfare: \(String(describing: aPlacemark.subThoroughfare))\n")
    }
}
