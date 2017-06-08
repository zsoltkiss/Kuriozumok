//
//  SearchSettingsViewController.swift
//  Kuriozumok
//
//  Created by Kiss Rudolf Zsolt on 2015. 11. 20..
//  Copyright © 2015. Kiss Rudolf Zsolt. All rights reserved.
//

import UIKit
import CoreLocation
import RxSwift
import RxAlamofire

class SearchSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var tvCategories: UITableView!
    @IBOutlet weak var scNearTo: UISegmentedControl!
    @IBOutlet weak var lbLocation: UILabel!
    @IBOutlet weak var scDistanceOptions: UISegmentedControl!
    
    fileprivate var cityWasSelected: Bool = false
    fileprivate var nameOfSelectedCity: String?
    
    fileprivate var categories = Array<Category>()
    
    fileprivate var locationManager: CLLocationManager!
    fileprivate var geocoder: CLGeocoder!
    fileprivate var placemark: CLPlacemark?
    
    fileprivate var hasGPSLocation: Bool = false
    
    fileprivate var serverResponseData: Data!
    
    private var disposeBag = DisposeBag()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // without this an unnecessary padding is displayed on top of table view
        self.tvCategories.contentInset = UIEdgeInsetsMake(-64, 0, 0, 0);
        
        self.tvCategories.backgroundColor = KuriozumokUtil.applicationColors()[2]
        
        self.locationManager = CLLocationManager()
        self.geocoder = CLGeocoder()
        
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.requestWhenInUseAuthorization()
        
        self.fetchCategories()
    }
    
    // MARK: - UITableViewDatasource protocol
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var currentCell: UITableViewCell!
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "CategorySelectorCell") {
            currentCell = cell
        } else {
            currentCell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "CategorySelectorCell")
        }
        
        let aCat = self.categories[indexPath.row]
        currentCell.textLabel?.text = aCat.title
        currentCell.textLabel?.textColor = UIColor.white
        currentCell.backgroundColor = KuriozumokUtil.applicationColors()[2]
        
        return currentCell
    }
    
    // MARK: - UITableViewDelegate protocol
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let aCat = self.categories[indexPath.row]
        aCat.selected = true
        
        let selectedCell = tableView.cellForRow(at: indexPath)
        selectedCell!.accessoryType = UITableViewCellAccessoryType.checkmark
        
        selectedCell?.selectionStyle = UITableViewCellSelectionStyle.none
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let aCat = self.categories[indexPath.row]
        aCat.selected = false
        
        let selectedCell = tableView.cellForRow(at: indexPath)
        selectedCell!.accessoryType = UITableViewCellAccessoryType.none

    }
    
    // MARK: - Public methods
    func userDidPickACity(_ selectedCity: String) {
        print("\(#function) called with \(selectedCity)")
        
        if !selectedCity.isEmpty {
            self.cityWasSelected = true
            self.nameOfSelectedCity = selectedCity
            let prefixString = NSLocalizedString("Near to", comment: "Text prefix on segmented control option")
            
            self.scNearTo.setTitle("\(prefixString) \(selectedCity)", forSegmentAt: 1)
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if "DisplayCityListSegue" == segue.identifier {
            
        } else if "DisplaySearchResultsSegue" == segue.identifier {
            let params = buildQueryParams()
            
            print("QUERY STRING: \(params.0)")
            print("QUERY PARAMS: \(params.1)")
            
            if let nextVC = segue.destination as? SearchResultsViewController {
                nextVC.searchParams = params.1
            }
        }
    }

    // MARK: - UI action handling
    @IBAction func nearToSegmentChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            let defaultSegmentText = NSLocalizedString("Near to this city", comment: "text for second option on segmented control")
            sender.setTitle(defaultSegmentText, forSegmentAt: 1)
            
            self.cityWasSelected = false
            self.nameOfSelectedCity = nil
        } else {
            self.performSegue(withIdentifier: "DisplayCityListSegue", sender: sender)
        }
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
            self.hasGPSLocation = true
            self.lbLocation.text = "\(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)"
//            print("Location found: \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
            
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
                        
                        // street number
                        print("subThoroughfare: \(String(describing: self.placemark?.subThoroughfare))\n")
                        
                        // street
                        print("thoroughfare: \(String(describing: self.placemark?.thoroughfare))\n")
                        
                        // ZIP code
                        print("postalCode: \(String(describing: self.placemark?.postalCode))\n")
                        
                        // county
                        print("administrativeArea: \(String(describing: self.placemark?.administrativeArea))\n")
                        
                        // city/town
                        print("locality: \(String(describing: self.placemark?.locality))\n")
                        print("country: \(String(describing: self.placemark?.country))\n")
                        
                        self.lbLocation.text = locationText
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
    fileprivate func fetchCategories() {
        json(.get, REQUEST_URL_CATEGORIES)
            .subscribe(onNext: { [weak self] in
                print("Categories fetched with RxAlamofire: \($0)")
                
                self?.categories = []
                
                if let arrayOfCategories = $0 as? [Dictionary<String, AnyObject>] {
                    for rawData in arrayOfCategories {
                        if let aCat = Category(dictionary: rawData) {
                            self?.categories.append(aCat)
                        }
                    }
                }
                
                self?.tvCategories.reloadData()
                
                }, onError: { error in
                    print("Categories fetch FAILED. \(error)")
                    
                    let connectionError = NSLocalizedString("Connection to server failed.", comment:"Server connection error message")
                    let title = NSLocalizedString("Error", comment:"Error message alert view title");
                    KuriozumokUtil.displayAlert(connectionError, title: title, delegate: nil)
            
            })
            .addDisposableTo(disposeBag)
    }
    
    private func buildQueryParams() -> (String, [String:Any]) {
        var queryString = "?"
        var queryParams = [String:Any]()
        
        if self.nameOfSelectedCity != nil {
            queryString += "town=\(self.nameOfSelectedCity!)"
            
            queryParams["town"] = self.nameOfSelectedCity!
            
        } else if self.hasGPSLocation {
            let deviceLocation = (UIApplication.shared.delegate as! AppDelegate).deviceLocation
            
            queryString += "latitude=\(deviceLocation!.coordinate.latitude)"
            queryString += "&longitude=\(deviceLocation!.coordinate.longitude)"
            
            queryParams["latitude"] = "\(deviceLocation!.coordinate.latitude)"
            queryParams["longitude"] = "\(deviceLocation!.coordinate.longitude)"
        }
        
        var distance = 1
        
        if self.scDistanceOptions.selectedSegmentIndex == 1 {
            distance = 3;
        } else if self.scDistanceOptions.selectedSegmentIndex == 2 {
            distance = 5;
        }
        
        queryString += "&distance=\(distance)"
        queryParams["distance"] = "\(distance)"
        
        for aCategory in self.categories {
            if aCategory.selected {
                let part = "&ids[]=\(aCategory.categoryId!)"
                
                queryString += part
            }
        }
        
        let selectedCategoryIds = self.categories.filter { $0.selected }
            .flatMap { $0.categoryId }
        queryParams["ids"] = selectedCategoryIds
        
        return (queryString, queryParams)
    }
}
