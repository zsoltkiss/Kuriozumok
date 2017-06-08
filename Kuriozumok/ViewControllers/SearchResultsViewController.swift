//
//  SearchResultsViewController.swift
//  Kuriozumok
//
//  Created by Kiss Rudolf Zsolt on 2015. 11. 24..
//  Copyright © 2015. Kiss Rudolf Zsolt. All rights reserved.
//

import UIKit
import Alamofire
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


class SearchResultsViewController: UITableViewController, NSURLConnectionDataDelegate {
    
    @IBOutlet weak var lbHeaderInfoOrdering: UILabel!
    @IBOutlet weak var scOrdering: UISegmentedControl!
    
    var searchQuery: String!
    
    fileprivate weak var activityIndicator: UIActivityIndicatorView!
    fileprivate var serverResponseData: Data!
    fileprivate var searchResults = Array<NameCard>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Loading referenced header view from a seperate XIB
        if let topLevelObjectsInNib = Bundle.main.loadNibNamed("SearchResultsTableHeader", owner: self, options:nil) {
            self.tableView.tableHeaderView = (topLevelObjectsInNib[0] as! UIView)
            
            self.lbHeaderInfoOrdering.text = NSLocalizedString("Ordering", comment: "Table view header prompt")
            
            let segmentTitle1 = NSLocalizedString("By Name", comment: "Ordering option 1")
            let segmentTitle2 = NSLocalizedString("By Distance", comment: "Ordering option 2")
            
            self.scOrdering.setTitle(segmentTitle1, forSegmentAt: 0)
            self.scOrdering.setTitle(segmentTitle2, forSegmentAt: 1)
        }
        
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        indicator.hidesWhenStopped = true;
        
        self.view.addSubview(indicator)
        
        self.activityIndicator = indicator;
        self.activityIndicator.translatesAutoresizingMaskIntoConstraints = false;
        self.activityIndicator.color = APP_COLOR_BLUE
        
        
        let centerXConstr = NSLayoutConstraint(item: self.activityIndicator, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0.0)
        let centerYConstr = NSLayoutConstraint(item: self.activityIndicator, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1.0, constant: 0.0)
        
        self.view.addConstraint(centerXConstr)
        self.view.addConstraint(centerYConstr)
        
        self.activityIndicator.startAnimating()
        
        self.fetchSearchResults()
        
//        self.fetchSearchResultsAlamo()

    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchResults.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath)

        if let src = cell as? SearchResultCell {
            let aCard = self.searchResults[indexPath.row]
            
            src.customize(withNameCard: aCard)
        }

        return cell
    }

    
   // MARK: - UITableViewDelegate protocol
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "ShowNameCardDetailsSegue", sender: nil)
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if "ShowNameCardDetailsSegue" == segue.identifier {
            
            if let nextVC = segue.destination as? NameCardDetailsViewController {
                let rowIndex = self.tableView.indexPathForSelectedRow?.row
                
                let selNC = self.searchResults[rowIndex!]
                print("selected namecard before handed to next VC: \(selNC)")
                
                nextVC.selectedNameCard = selNC
            }
        } else if "MapSegue" == segue.identifier {
            // TODO: use real center coordinate instead
            
            // Gyulai Vár: 46.645996, 21.286005
//            CLLocationCoordinate2D centerCoords = CLLocationCoordinate2DMake(46.645996, 21.286005);
            
            if let nextVC = segue.destination as? SearchResultOnMapViewController {
                nextVC.results = self.searchResults
            }
            
        }
    }
    
    
    
    // MARK: - Action handling
    
    @IBAction func orderingChanged(_ sender: UISegmentedControl) {
        
        if sender.selectedSegmentIndex == 0 {
            self.orderByName()
        } else {
            self.orderByDistance()
        }
        
        self.tableView.reloadData()
        
    }
    
    // MARK: - NSURLConnectionDataDelegate
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        self.activityIndicator.stopAnimating();
        
        print("\(error)")
        
        self.displayConnectionError()

    }
    
    func connection(_ connection: NSURLConnection, didReceive response: URLResponse) {
        self.serverResponseData = Data()
    }
   
    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        self.serverResponseData.append(data)
    }
    
  
    func connectionDidFinishLoading(_ connection: NSURLConnection) {
        
        let someStructure = (try! JSONSerialization.jsonObject(with: self.serverResponseData!, options: JSONSerialization.ReadingOptions.mutableContainers))
        print("JSON response for search results fetch: \(someStructure)")
        
        if let arrayOfNameCards = someStructure as? NSArray {
            for rawData in arrayOfNameCards {
                let aCard = NameCard(dictionary: rawData as! Dictionary)
                
                self.searchResults.append(aCard)
                
            }
        } else if let onlyOneCard = someStructure as? NSDictionary {
            let aCard = NameCard(dictionary: onlyOneCard as! Dictionary<String, AnyObject>)
            self.searchResults.append(aCard)
        } else {
            print("What the heck the server has sent us?? >> \(someStructure)")
        }
     
//        let arrayOfNameCards: NSArray = (try! NSJSONSerialization.JSONObjectWithData(self.serverResponseData!, options: NSJSONReadingOptions.MutableContainers)) as! NSArray
        
//        print("JSON response for search results fetch: \(arrayOfNameCards)")
        
        
        
        self.activityIndicator.stopAnimating()
        
        self.orderByName()
        self.tableView.reloadData()
    
    }

    
    
    // MARK: - Private methods
    
    fileprivate func fetchSearchResultsAlamo() {
        let fullUrlAsString = REQUEST_URL_SEARCH + self.searchQuery
        
        let alamoReq = Alamofire.request(fullUrlAsString)
        
        alamoReq.responseJSON { (alamoResponse) -> Void in
            
            if let req = alamoResponse.request {
                print(req)  // original URL request
            }
            
            if let res = alamoResponse.response {
                print(res) // URL response
            }
            
            if let data = alamoResponse.data {
                print(data)     // server data
            }
            
            print(alamoResponse.result)   // result of response serialization
            
//            if let result = alamoResponse.result {
//                
//            }
            
            if (alamoResponse.response!).statusCode == 200 {
                
                if let responseAsJson = alamoResponse.result.value {
                    print("JSON response for search results fetch: \(responseAsJson)")
                    
                    if let arrayOfNameCards = responseAsJson as? NSArray {
                        for rawData in arrayOfNameCards {
                            let aCard = NameCard(dictionary: rawData as! Dictionary)
                            
                            self.searchResults.append(aCard)
                            
                        }
                    } else if let onlyOneCard = responseAsJson as? NSDictionary {
                        let aCard = NameCard(dictionary: onlyOneCard as! Dictionary<String, AnyObject>)
                        self.searchResults.append(aCard)
                    }
                    
                    self.orderByName()
                    self.tableView.reloadData()
                    
                    if self.searchResults.count == 0 {
                        self.displayNoResultsInfoMessage()
                    }
                    
                }
                
                
            } else {
                print("\(String(describing: alamoResponse.result.error))")
                self.displayServerError()
            }
            
            
            self.activityIndicator.stopAnimating()
            
            

        }
        
    }
    
    fileprivate func fetchSearchResults() {
        if (self.searchQuery != nil) {
            
            let fullUrlAsString = REQUEST_URL_SEARCH + self.searchQuery
            print("Full search url: \(fullUrlAsString)")
            
            let escapedPath = fullUrlAsString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            print("Url escaped: \(String(describing: escapedPath))")
            
            let url = URL(string: escapedPath!)
            let request = URLRequest(url: url!)
            
//            _ = NSURLConnection(request: request, delegate: self)
            
            NSURLConnection.sendAsynchronousRequest(request, queue: OperationQueue.main, completionHandler: { (response, data, error) -> Void in
                if error != nil {
                    print("\(String(describing: error))")
                    self.displayServerError()
                    
                } else {
                    print("Response to name card search request: \(String(describing: response))")
                    
                    if (response as! HTTPURLResponse).statusCode == 200 {
                        
                        let someStructure = (try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers))
                        print("JSON response for search results fetch: \(someStructure)")
                        
                        if let arrayOfNameCards = someStructure as? NSArray {
                            for rawData in arrayOfNameCards {
                                let aCard = NameCard(dictionary: rawData as! Dictionary)
                                
                                self.searchResults.append(aCard)
                                
                            }
                        } else if let onlyOneCard = someStructure as? NSDictionary {
                            let aCard = NameCard(dictionary: onlyOneCard as! Dictionary<String, AnyObject>)
                            self.searchResults.append(aCard)
                        }
                    } else {
                        self.displayServerError()
                    }
                    
                    
                    self.activityIndicator.stopAnimating()
                    
                    self.orderByName()
                    self.tableView.reloadData()
                    
                    if self.searchResults.count == 0 {
                        self.displayNoResultsInfoMessage()
                    }
                    
                }
            })
            
        }
    }
    

    func orderByName() {
        let sortedNameCards = self.searchResults.sorted(by: { (nc1, nc2) -> Bool in
            nc1.name < nc2.name
        })
        self.searchResults = sortedNameCards

        
        
//        self.searchResults.sortInPlace { (nc1, nc2) -> Bool in
//            return nc1.name < nc2.name
//        }
    }
    
    
    func orderByDistance() {
        
        let locationOfDevice = (UIApplication.shared.delegate as! AppDelegate).deviceLocation
        
        let sortedNameCards = self.searchResults.sorted(by: { (nc1, nc2) -> Bool in
            let dist1 = nc1.distanceFromLocationInMeters(locationOfDevice)
            let dist2 = nc2.distanceFromLocationInMeters(locationOfDevice)
            
            return dist1 < dist2
        })
        self.searchResults = sortedNameCards
        
//        self.searchResults.sortInPlace { (nc1, nc2) -> Bool in
//            let dist1 = nc1.distanceFromLocationInMeters(locationOfDevice)
//            let dist2 = nc2.distanceFromLocationInMeters(locationOfDevice)
//            
//            return dist1 < dist2
//        }
    }
    
    
 
    // MARK: - Private methods
    fileprivate func displayServerError() {
        let connectionError = NSLocalizedString("Search request failed.", comment:"Name card search error message")
        let title = NSLocalizedString("Error", comment:"Error message alert view title")
        
        KuriozumokUtil.displayAlert(connectionError, title: title, delegate: nil)

    }
    
    fileprivate func displayConnectionError() {
        let connectionError = NSLocalizedString("Connection to server failed.", comment:"Server connection error message")
        let title = NSLocalizedString("Error", comment:"Error message alert view title")
        
        KuriozumokUtil.displayAlert(connectionError, title: title, delegate: nil)
        
    }
    
    fileprivate func displayNoResultsInfoMessage() {
        let title = NSLocalizedString("No results found.", comment:"Alert view title when there are no any search results.")
        let message = NSLocalizedString("Please set a different search criteria.", comment:"Alert view message when there are no any search results.")
        
        
        KuriozumokUtil.displayAlert(message, title: title, delegate: nil)
        
    }

    



}
