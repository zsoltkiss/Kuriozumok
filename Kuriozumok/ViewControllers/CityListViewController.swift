//
//  CityListViewController.swift
//  Kuriozumok
//
//  Created by Kiss Rudolf Zsolt on 2015. 11. 23..
//  Copyright © 2015. Kiss Rudolf Zsolt. All rights reserved.
//

import UIKit
import RxSwift
import RxAlamofire

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


class CityListViewController: UITableViewController, UISearchResultsUpdating {
    var resultSearchController:UISearchController!
    
    fileprivate var serverResponseData: Data!
    fileprivate var cities = Array<String>()
    fileprivate var filteredData = Array<String>()
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("List of cities", comment: "Title on navbar")

        resultSearchController = UISearchController(searchResultsController: nil)
        resultSearchController.searchResultsUpdater = self
        resultSearchController.hidesNavigationBarDuringPresentation = false
        resultSearchController.dimsBackgroundDuringPresentation = false
        resultSearchController.searchBar.searchBarStyle = UISearchBarStyle.prominent
        resultSearchController.searchBar.sizeToFit()
        
        self.tableView.backgroundColor = KuriozumokUtil.applicationColors()[2]
        self.tableView.tableHeaderView = resultSearchController.searchBar
        self.fetchCities()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if resultSearchController.isActive {
            return filteredData.count
        }
        else {
            return self.cities.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var currentCell: UITableViewCell!
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "CityCell") {
            currentCell = cell
        } else {
            currentCell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "CityCell")
        }
        
        
        if resultSearchController.isActive {
            currentCell.textLabel?.text = filteredData[indexPath.row]
        }
        else {
            currentCell.textLabel?.text = self.cities[indexPath.row]
        }
        
        currentCell.backgroundColor = KuriozumokUtil.applicationColors()[2]
        currentCell.textLabel?.textColor = UIColor.white
        
        return currentCell
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var nameOfSelectedCity: String!
        
        if self.resultSearchController.isActive {
            nameOfSelectedCity = self.filteredData[indexPath.row]
        } else {
            nameOfSelectedCity = self.cities[indexPath.row]
        }
        
        if let nc = self.navigationController {
            if let previousVC = nc.viewControllers[nc.viewControllers.count - 2] as? SearchSettingsViewController {
                self.resultSearchController.isActive = false
                previousVC.userDidPickACity(nameOfSelectedCity)
                nc.popViewController(animated: true)
            }
        }
    }
    
    // MARK: - UISearchResultUpdating protocol
    func updateSearchResults(for searchController: UISearchController) {
        if searchController.searchBar.text?.characters.count > 0 {
            
            filteredData.removeAll(keepingCapacity: false)
            let searchPredicate = NSPredicate(format: "SELF CONTAINS[c] %@", searchController.searchBar.text!)
            let array = (self.cities as NSArray).filtered(using: searchPredicate)
            filteredData = array as! [String]
            tableView.reloadData()
            
        } else {
            filteredData.removeAll(keepingCapacity: false)
            filteredData = self.cities
            tableView.reloadData()
        }
    }
    
    // MARK: - Private methods
    fileprivate func fetchCities() {
        json(.get, REQUEST_URL_CITIES)
            .subscribe(onNext: { [weak self] in
                print("Cities fetched with RxAlamofire: \($0)")
                
                self?.cities = []
                
                if let arrayOfCities = $0 as? [String] {
                    for rawData in arrayOfCities {
                        self?.cities.append(rawData)
                    }
                }
                
                self?.tableView.reloadData()
                
                }, onError: { error in
                    print("Cities fetch FAILED. \(error)")
                    
                    let connectionError = NSLocalizedString("Connection to server failed.", comment:"Server connection error message")
                    let title = NSLocalizedString("Error", comment:"Error message alert view title");
                    KuriozumokUtil.displayAlert(connectionError, title: title, delegate: nil)
            })
            .addDisposableTo(disposeBag)
    }
}
