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
                
//                if let postRequest = self.createPostRequestWithJSONContent() {
////                if let postRequest = self.createPostRequestTheOldWay() {
//                    print("POST REQUEST CREATED SUCCESSFULLY: \(postRequest)")
//                
//                    NSURLConnection.sendAsynchronousRequest(postRequest, queue: NSOperationQueue.mainQueue(), completionHandler: { (response, data, error) -> Void in
//                        
//                        self.activityIndicator?.stopAnimating()
//                        if error != nil || (response! as! NSHTTPURLResponse).statusCode != 200 {
//                            if response != nil {
//                                print("RESPONSE to proposal: \(response)")
//                            }
//                            
//                            if data != nil {
//                                let strData = String(data: data!, encoding: NSUTF8StringEncoding)
//                                print("DATA in response: \(strData)")
//                            }
//                            
//                            print("ERROR in response: \(error)")
//                        } else {
//                            
//                            let jsonReponse = (try! NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers))
//                            
//                            print("JSON response: \(jsonReponse)")
//                        }
//                        
//                        self.imageImported1 = nil
//                        self.imageImported2 = nil
//                        
//                        let placeholderImage = UIImage(named: "image_placeholder")
//                        self.imageView1.image = placeholderImage
//                        self.imageView2.image = placeholderImage
//                        
//                        self.tfName.text = ""
//                        self.tvDescription.text = ""
//                        
//                        
//                    })
//                }
                
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
        
        // Resize the image from the camera
        //        UIImage *scaledImage = [photoImage resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(_targetView.frame.size.width, _targetView.frame.size.height) interpolationQuality:kCGInterpolationHigh];
        // Crop the image to a square (yikes, fancy!)
        //        UIImage *croppedImage = [scaledImage croppedImage:CGRectMake((scaledImage.size.width -_targetView.frame.size.width)/2, (scaledImage.size.height - _targetView.frame.size.height)/2, _targetView.frame.size.width, _targetView.frame.size.height)];
    }
    
//    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
//        
//    }
    
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
    
//    fileprivate func addGestureRecognizers() {
//        let rec1 = UITapGestureRecognizer(target: self, action: #selector(ProposalViewController.imageTapped(_:)))
//        let rec2 = UITapGestureRecognizer(target: self, action: #selector(ProposalViewController.imageTapped(_:)))
//        
//        self.imageView1.addGestureRecognizer(rec1)
//        self.imageView2.addGestureRecognizer(rec2)
//    }
    
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
    
    fileprivate func createPostRequest(_ boundaryString: String) -> NSMutableURLRequest {
        
        
        let postUrl = URL(string: REQUEST_URL_PROPOSAL)
        let postRequest = NSMutableURLRequest(url: postUrl!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 10.0)
        postRequest.httpMethod = "POST"
        postRequest.timeoutInterval = 60.0
        
        let valueForContentTypeHeader = "multipart/form-data; boundary=\(boundaryString)"
        postRequest.setValue(valueForContentTypeHeader, forHTTPHeaderField: "ContentType")
        
//        let httpBody = self.createPostBody(uniqueBoundaryString)
//        postRequest.HTTPBody = httpBody
        
        print("POST REQUEST: \(postRequest)")
        
        return postRequest

    }
    
    fileprivate func createPostBody(_ boundaryString: String) -> NSMutableData {
        let body = NSMutableData()
        
        // Post param "latitude"
        body.append(self.boundaryDataWithNewLine(boundaryString))
        body.append(self.contentDispositionRowForStringParam("latitude"))
        let strLatitude = "\(self.gpsLocationOfCurio!.coordinate.latitude)"
        body.append(self.dataFromStringParam(strLatitude))
        
        // Post param "longitude"
        body.append(self.boundaryDataWithNewLine(boundaryString))
        body.append(self.contentDispositionRowForStringParam("longitude"))
        let strLongitude = "\(self.gpsLocationOfCurio!.coordinate.longitude)"
        body.append(self.dataFromStringParam(strLongitude))
        
        // Post param "title"
        body.append(self.boundaryDataWithNewLine(boundaryString))
        body.append(self.contentDispositionRowForStringParam("title"))
        body.append(self.dataFromStringParam(self.tfName.text!))
        
        
        // Post param "town"
        if self.postDataTown.isEmpty == false {
            print("town: \(self.postDataTown)")
            
            body.append(self.boundaryDataWithNewLine(boundaryString))
            body.append(self.contentDispositionRowForStringParam("town"))
            body.append(self.dataFromStringParam(self.postDataTown))
        }
        
        // Post param "address"
        if self.postDataAddress.isEmpty == false {
            print("address: \(self.postDataAddress)")
            
            body.append(self.boundaryDataWithNewLine(boundaryString))
            body.append(self.contentDispositionRowForStringParam("address"))
            body.append(self.dataFromStringParam(self.postDataAddress))
        }
        
        // Post param "description"
        if self.tvDescription.text!.isEmpty == false {
            print("description: \(self.tvDescription.text)")
            
            body.append(self.boundaryDataWithNewLine(boundaryString))
            body.append(self.contentDispositionRowForStringParam("description"))
            body.append(self.dataFromStringParam(self.tvDescription.text))

        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        
        // Post param "photo1"
        if self.imageImported1 != nil {
            
            let fileNameFromImportDate = formatter.string(from: self.imageDate1!)
            
            body.append(self.boundaryDataWithNewLine(boundaryString))
            body.append(self.contentDispositionRowForImage("photo1", filename: "\(fileNameFromImportDate).png"))
            body.append(self.dataFromContentType("image/png"))
            
            let imageData = UIImagePNGRepresentation(self.imageImported1!)
            body.append(imageData!)
            body.append(self.dataFromLineFeed())
            
        }
        
        // Post param "photo2"
        if self.imageImported2 != nil {
            
            let fileNameFromImportDate = formatter.string(from: self.imageDate2!)
            
            body.append(self.boundaryDataWithNewLine(boundaryString))
            body.append(self.contentDispositionRowForImage("photo2", filename: "\(fileNameFromImportDate).png"))
            body.append(self.dataFromContentType("image/png"))
            
            let imageData = UIImagePNGRepresentation(self.imageImported2!)
            body.append(imageData!)
            body.append(self.dataFromLineFeed())
            
        }

        body.append(self.boundaryDataWithNewLine(boundaryString))
        
        let checkString = String(data: body as Data, encoding: String.Encoding.utf8)
        print("POST BODY: \(checkString!)")
        
        
        return body
    }
    
    fileprivate func contentDispositionRowForStringParam(_ paramName: String) -> Data {
        let dispositionRow = "Content-Disposition: form-data; name=\"\(paramName)\"\r\n"
        let cdrData = dispositionRow.data(using: String.Encoding.utf8)
        return cdrData!
    }
    
    
    fileprivate func contentDispositionRowForImage(_ paramName: String, filename: String) -> Data {
        let dispositionRow = "Content-Disposition: form-data; name=\"\(paramName)\"; filename=\"\(filename)\""
        let cdrData = dispositionRow.data(using: String.Encoding.utf8)
        return cdrData!
    }
    
    fileprivate func dataFromStringParam(_ paramValue: String) -> Data {
        let valueRow = "\(paramValue)\r\n"
        let vrData = valueRow.data(using: String.Encoding.utf8)
        
        return vrData!
    }
    
    fileprivate func dataFromContentType(_ value: String) -> Data {
        let valueRow = "Content-Type: \(value)\r\n\r\n"
        let vrData = valueRow.data(using: String.Encoding.utf8)
        
        return vrData!
    }
    
    fileprivate func dataFromLineFeed() -> Data {
        return "\r\n".data(using: String.Encoding.utf8)!
    }

    fileprivate func boundaryDataWithNewLine(_ boundaryString: String) -> Data {
        let boundaryAndNewLine = "\(boundaryString)\r\n"
        let bData = boundaryAndNewLine.data(using: String.Encoding.utf8)
        
        return bData!
    }
    
    fileprivate func boundaryString() -> String {
//        let uniquePart = NSUUID().UUIDString
        
        let uniquePart = Date().timeIntervalSince1970 * 1000000
        
        return "-----------------------------\(uniquePart)"
    }
    
    
    fileprivate func createPostRequestTheOldWay() -> NSMutableURLRequest? {
        let postUrl = URL(string: REQUEST_URL_PROPOSAL)
        let postRequest = NSMutableURLRequest(url: postUrl!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 60.0)
        postRequest.httpMethod = "POST"
//        postRequest.addValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        postRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        print("POST DATA: ")
        print("title: \(self.tfName.text!)")
        var postBody = "title=\(self.tfName.text!)"
        
        
        print("latitude: \(self.gpsLocationOfCurio!.coordinate.latitude)")
        print("longitude: \(self.gpsLocationOfCurio!.coordinate.longitude)")
        postBody += "&latitude=\(self.gpsLocationOfCurio!.coordinate.latitude)"
        postBody += "&longitude=\(self.gpsLocationOfCurio!.coordinate.longitude)"
        
        if self.postDataTown.isEmpty == false {
            print("town: \(self.postDataTown)")
            postBody += "&town=\(self.postDataTown)"
        }
        
        if self.postDataAddress.isEmpty == false {
            print("address: \(self.postDataAddress)")
            postBody += "&address=\(self.postDataAddress)"
        }
        
        if self.tvDescription.text!.isEmpty == false {
            print("description: \(self.tvDescription.text)")
            postBody += "&description=\(self.tvDescription.text)"
        }
        
        
        if self.imageImported1 != nil {
            let imageData = UIImagePNGRepresentation(self.imageImported1!)
            let base64String = imageData!.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
            
            print("photo1: \(imageData!.count) bytes")
            
            postBody += "&photo1=\(base64String)"
        }
        
        if self.imageImported2 != nil {
            let imageData = UIImagePNGRepresentation(self.imageImported2!)
            let base64String = imageData!.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
            
            print("photo2: \(imageData!.count) bytes")
            
            postBody += "&photo2=\(base64String)"
        }
        

        postRequest.httpBody = postBody.data(using: String.Encoding.utf8)
        
        return postRequest
    }
    
//    fileprivate func createPostRequestWithJSONContent() -> NSMutableURLRequest? {
//        let postUrl = URL(string: REQUEST_URL_PROPOSAL)
//        let postRequest = NSMutableURLRequest(url: postUrl!, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 60.0)
//        postRequest.httpMethod = "POST"
//        postRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
////        postRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//        
//        
//        var params = [String: AnyObject]()
//    
//        
//        params["title"] = self.tfName.text! as AnyObject
//        params["latitude"] = "\(self.gpsLocationOfCurio!.coordinate.latitude)" as AnyObject
//        params["longitude"] = "\(self.gpsLocationOfCurio!.coordinate.longitude)" as AnyObject
//
//        if self.postDataTown.isEmpty == false {
//            params["town"] = self.postDataTown as AnyObject
//        }
//        
//        if self.postDataAddress.isEmpty == false {
//            params["address"] = self.postDataAddress as AnyObject
//        }
//        
//        if self.tvDescription.text!.isEmpty == false {
//            params["description"] = self.tvDescription.text as AnyObject
//        }
//        
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
//        
//        if self.imageImported1 != nil {
//            let fileNameFromImportDate = formatter.string(from: self.imageDate1!)
//            
//            let imageData = UIImagePNGRepresentation(self.imageImported1!)
//            let base64String = imageData!.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
//            
//            params["photo1"] = [ "Content-Type": "image/png", "filename":"\(fileNameFromImportDate).png", "file_data": base64String]
//            
////            print("photo1: \(imageData!.length) bytes, filename=\(fileNameFromImportDate)")
//            
//        }
//        
//        if self.imageImported2 != nil {
//            let fileNameFromImportDate = formatter.string(from: self.imageDate2!)
//            
//            let imageData = UIImagePNGRepresentation(self.imageImported2!)
//            
//            let base64String = imageData!.base64EncodedString(options: NSData.Base64EncodingOptions.lineLength64Characters)
//            
//            params["photo2"] = [ "Content-Type": "image/png", "filename":"\(fileNameFromImportDate).png", "file_data": base64String]
//            
////            print("photo2: \(imageData!.length) bytes, filename=\(fileNameFromImportDate)")
//        }
//        
//        print("Params: \(params)")
//
//        do {
//            let postData = try JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions(rawValue: 0))
//            postRequest.httpBody = postData
//            print("POST BODY CREATION SUCCESS.")
//            
//        } catch (_) {
//            print("POST BODY CREATION FAILED.")
//            return nil
//        }
//
//        return postRequest
//        
//    }
    
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
        
        
        
        
//        Alamofire.upload(.POST, REQUEST_URL_PROPOSAL, multipartFormData: { (multipartFormData) -> Void in
//
//
//            let titleData = self.tfName.text!.dataUsingEncoding(NSUTF8StringEncoding)
//            multipartFormData.appendBodyPart(data: titleData!, name: "title")
//            print("TITLE added to multipart form data: \(self.tfName.text!)")
//            
//            let latitudeData = "\(self.gpsLocationOfCurio!.coordinate.latitude)".dataUsingEncoding(NSUTF8StringEncoding)
//            multipartFormData.appendBodyPart(data: latitudeData!, name: "latitude")
//            print("LATITUDE added to multipart form data: \(self.gpsLocationOfCurio!.coordinate.latitude)")
//
//            
//            let longitudeData = "\(self.gpsLocationOfCurio!.coordinate.longitude)".dataUsingEncoding(NSUTF8StringEncoding)
//            multipartFormData.appendBodyPart(data: longitudeData!, name: "longitude")
//            print("LONGITUDE added to multipart form data: \(self.gpsLocationOfCurio!.coordinate.longitude)")
//
//            
//            if self.postDataTown.isEmpty == false {
//                let townData = self.postDataTown.dataUsingEncoding(NSUTF8StringEncoding)
//                multipartFormData.appendBodyPart(data: townData!, name: "town")
//                print("TOWN added to multipart form data: \(self.postDataTown)")
//
//            }
//            
//            if self.postDataAddress.isEmpty == false {
//                let addressData = self.postDataAddress.dataUsingEncoding(NSUTF8StringEncoding)
//                multipartFormData.appendBodyPart(data: addressData!, name: "address")
//                print("ADDRESS added to multipart form data: \(self.postDataAddress)")
//
//            }
//            
//            if self.tvDescription.text!.isEmpty == false {
//                let descriptionData = self.tvDescription.text.dataUsingEncoding(NSUTF8StringEncoding)
//                multipartFormData.appendBodyPart(data: descriptionData!, name: "description")
//                print("DESCRIPTION added to multipart form data: \(self.tvDescription.text!)")
//
//            }
//
//            let formatter = NSDateFormatter()
//            formatter.dateFormat = "yyyy-MM-dd_HHmmss"
//
//            if self.imageImported1 != nil {
//                let fileExtension = ".jpg"  //".png"
//                let mimeType = "image/jpg"             // "image/png"
//                
//                let fileNameFromImportDate = formatter.stringFromDate(self.imageDate1!) + fileExtension
//                
//            
//                
//                let imageData = UIImageJPEGRepresentation(self.imageImported1!, 0.8);
//                //The float param (0.8 in this example) is the compression quality
//                //expressed as a value from 0.0 to 1.0, where 1.0 represents
//                //the least compression (or best quality).
//                
//                multipartFormData.appendBodyPart(data: imageData!, name: "photo1", fileName: fileNameFromImportDate, mimeType: mimeType)
//                print("PHOTO1 added to multipart form data: \(fileNameFromImportDate)")
//
//                
//            }
//            
//            if self.imageImported2 != nil {
//                let fileNameFromImportDate = formatter.stringFromDate(self.imageDate2!) + ".png"
//                
//                let imageData = UIImagePNGRepresentation(self.imageImported2!)
//                
//                 multipartFormData.appendBodyPart(data: imageData!, name: "photo2", mimeType: "image/png")
//                print("PHOTO2 added to multipart form data: \(fileNameFromImportDate)")
//
//                
//            }
//
//            
//
//            }) { (encodingResult) -> Void in
//                print("Result of Alamofire upload: \(encodingResult)\n----------------------\n")
//                
//                switch encodingResult {
//                case .Success(let upload, _, _):
//                    print("Result: .Success")
//
//                    upload.response(completionHandler: { (req, res, resData, resError) -> Void in
//                        print("in completion handler, res: \(res)")
//                        print("in completion handler, resData: \(NSString(data: resData!, encoding: NSUTF8StringEncoding))")
//                        print("in completion handler, resError: \(resError)")
//                    })
//                    
//                case .Failure(let encodingError):
//                    print("Result: .Failure")
//                    print(encodingError)
//                }
//                
//                
//                self.activityIndicator?.stopAnimating()
//                
//                
//                self.imageImported1 = nil
//                self.imageImported2 = nil
//                
//                let placeholderImage = UIImage(named: "image_placeholder")
//                self.imageView1.image = placeholderImage
//                self.imageView2.image = placeholderImage
//                
//                self.tfName.text = ""
//                self.tvDescription.text = ""
//                
//                self.navigationController?.popViewControllerAnimated(true)
//
//                
//        }
    }
    
}
