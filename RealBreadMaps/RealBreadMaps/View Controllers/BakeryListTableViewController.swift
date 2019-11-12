//
//  BakeryListTableViewController.swift
//  RealBreadMaps
//
//  Created by Audrey Welch on 3/19/19.
//  Copyright © 2019 Audrey Welch. All rights reserved.
//

import UIKit
import CoreLocation

class BakeryListTableViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet weak var bakerySearchBar: UISearchBar!
    
    var bakeries: [Bakery] = []
    
    var filteredBakeries: [Bakery] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bakerySearchBar.delegate = self
        
        bakeryFetch()
        
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        
        bakerySearchBar.tintColor = .roseRed
        
        // Cells should determine their own height
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        
//        self.bakeries = BakeryModelController.shared.bakeries
        
        //sortByDistance()
        
        //BakeryMapViewController.convertMetersToMiles(of: bakeries[0].distanceFromUser!)
 
    }
    
    // Fetch function if user taps on List View before Map View
    func bakeryFetch() {
        
        if BakeryModelController.shared.bakeries.count == 0 {
            
            // Perform the fetch on a background queue
            DispatchQueue.global(qos: .userInitiated).async {

                // For each bakery in the firebaseBakeries array
                for eachFirebaseBakery in BakeryModelController.shared.firebaseBakeries {

                    // Use the placeID to make the GooglePlaces API call
                    BakeryModelController.shared.getBakeryInfo(with: eachFirebaseBakery.placeID) { (error) in
                        self.bakeries = BakeryModelController.shared.bakeries

                        if BakeryModelController.shared.userLocation != nil {
                            DispatchQueue.main.async {
                                // Sort is performed in fetch function, so only sort in table view if
                                // user taps on List View before Map View, therefore userLocation was nil
                                self.sortByDistance()
                            }
                        }
                       
                    }
                }
            }
        } else {
            bakeries = BakeryModelController.shared.bakeries
            //sortByDistance()
        }
    }
    
    // Sort the bakeries by distance away from user and reload the table view
    func sortByDistance() {
        
        if BakeryModelController.shared.userLocation == nil {
            return
        } else {
            bakeries.sort { (l1, l2) -> Bool in
                return Double(l1.distanceFromUser!) < Double(l2.distanceFromUser!)
            }
                
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
  
    }
    
    // MARK: - Table View Data Source Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchBarIsEmpty() == false {
            return filteredBakeries.count
        }

        return self.bakeries.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bakeryCell", for: indexPath)
            
        guard let bakeryCell = cell as? BakeryTableViewCell else { return cell }
        
        let defaultImageURL = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=CmRZAAAAKXl1BpFclUAmGrcHUZC1nmBk5Gu6SSrbegXHbrSJ2xSDKr13jDIpKAEQpTvJjU5u0IyITt0S5apoGvv5dL5IBdy1ET8Y2ccXpImRpP4xvWuwiD85fTb9i0_IWYjbpnzUEhDrSacgBovoAs-V4RHh3UsvGhQWHhbDYuBSid5EFV7bJ49sRqwL_g&key=\(GMSPlacesClientApiKey)"
        
        let baseURL = URL(string: "https://maps.googleapis.com/maps/api/place/")!
        
        bakeryCell.bakeryDistanceLabel.adjustsFontForContentSizeCategory = true
        bakeryCell.bakeryImageView?.layer.cornerRadius = 10
        bakeryCell.bakeryImageView?.layer.masksToBounds = true
//        bakeryCell.bakeryImageView?.layer.borderColor = UIColor.lightGray.cgColor
//        bakeryCell.bakeryImageView?.layer.borderWidth = 0.75
        
        // Searched-for bakeries
        if searchBarIsEmpty() == false {
            //bakeryCell.bakeryNameLabel.text = filteredBakeries[indexPath.row].name
            bakeryCell.bakeryNameLabel.text = BakeryListTableViewController.bakeryNameSpecifications(bakery: filteredBakeries[indexPath.row])
            
            let splitAddressArray = filteredBakeries[indexPath.row].formattedAddress.components(separatedBy: ", ")
            bakeryCell.bakeryAddressLabel.text = determineAddressFormatting(array: splitAddressArray)
            
            if let unwrappedDistance = filteredBakeries[indexPath.row].distanceFromUser {
                bakeryCell.bakeryDistanceLabel.text = "\(BakeryMapViewController.self.convertMetersToMiles(of: unwrappedDistance)) miles away"
            } else {
                bakeryCell.bakeryDistanceLabel.isHidden = true
            }
            
            if filteredBakeries[indexPath.row].photos == nil {
                bakeryCell.bakeryImageView.image = UIImage(named: "no_image_available")
    
            } else {
                let imageURLString = "\(baseURL)photo?maxwidth=400&photoreference=\(filteredBakeries[indexPath.row].photos![0].photoReference)&key=\(GMSPlacesClientApiKey)"
                bakeryCell.bakeryImageView.load(url: URL(string: imageURLString)!)
            }
        
        // Full list of bakeries
        } else {
            //bakeryCell.bakeryNameLabel.text = bakeries[indexPath.row].name
            bakeryCell.bakeryNameLabel.text = BakeryListTableViewController.bakeryNameSpecifications(bakery: bakeries[indexPath.row])
            
            let splitAddressArray = bakeries[indexPath.row].formattedAddress.components(separatedBy: ", ")
            bakeryCell.bakeryAddressLabel.text = determineAddressFormatting(array: splitAddressArray)

            if let unwrappedDistance = bakeries[indexPath.row].distanceFromUser {
                bakeryCell.bakeryDistanceLabel.text = "\(BakeryMapViewController.self.convertMetersToMiles(of: unwrappedDistance)) miles away"
            } else {
                bakeryCell.bakeryDistanceLabel.isHidden = true
            }

            if bakeries[indexPath.row].photos == nil {
                bakeryCell.bakeryImageView.image = UIImage(named: "no_image_available")
                
            } else {
                let imageURLString = "\(baseURL)photo?maxwidth=400&photoreference=\(bakeries[indexPath.row].photos![0].photoReference)&key=\(GMSPlacesClientApiKey)"
                bakeryCell.bakeryImageView.load(url: URL(string: imageURLString)!)
                
            }
        }
        return bakeryCell
    }
    
    func determineAddressFormatting(array: [String]) -> String {
        
        switch array.count {
        case 2:
            return "\(array[0])\n\(array[1])"
        case 3:
            return """
            \(array[0])
            \(array[1]), \(array[2])
            """
        case 4:
            return """
            \(array[0])
            \(array[1]), \(array[2]), \(array[3])
            """
        case 5:
            return """
            \(array[0]), \(array[1])
            \(array[2]), \(array[3]), \(array[4])
            """
        default:
            return array.joined(separator: ", ")
        }
    }
    
    static func bakeryNameSpecifications(bakery: Bakery) -> String {
        
        if bakery.name == "Manresa Bread" {
            if bakery.formattedAddress.contains("Los Gatos") {
                return "Manresa Bread - Los Gatos"
            } else if bakery.formattedAddress.contains("Los Altos") {
                return "Manresa Bread - Los Altos"
            } else if bakery.formattedAddress.contains("Campbell") {
                return "Manresa Bread - Campbell All Day"
            }
        } else if bakery.name == "Lodge Bread Company" {
            if bakery.formattedAddress.contains("Woodland Hills") {
                return "Lodge Bread Company - Woodland Hills"
            }
        } else if bakery.name == "Tartine" {
            if bakery.formattedAddress.contains("Los Angeles") {
                return "Tartine - The Manufactory"
            }
        }
            
        return bakery.name
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationVC = segue.destination as? BakeryDetailViewController,
            let indexPath = tableView.indexPathForSelectedRow else { return }
        
        var bakery: Bakery
        
        if searchBarIsEmpty() == false {
            bakery = filteredBakeries[indexPath.row]
            destinationVC.bakery = bakery

        } else {
            
            bakery = bakeries[indexPath.row]
            destinationVC.bakery = bakery
        }

        // Detail View Controller uses currentBakeryName to confirm which bakery to show - it needs to be reset to reflect the correct bakery after a detail view screen has been shown via map view selection
        BakeryModelController.shared.currentBakeryName = bakery.name
        BakeryModelController.shared.currentBakeryAddress = bakery.formattedAddress
    }
    
    // MARK: - UI Search Bar
    
    // Tell the delegate that the search button was tapped
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
        
        filterBakeries()
        
        self.tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.tableView.reloadData()
    }
    
    func filterBakeries() {
        
        DispatchQueue.main.async {
            
            // Grab the text, make sure it's not empty
            guard let searchTerm = self.bakerySearchBar.text?.lowercased(), !searchTerm.isEmpty else {
                // If no search term, display all of the bakeries
                self.filteredBakeries = self.bakeries
                return
            }
            
            // Filter through the array of bakeries to see if name of bakery or address contain the text entered by user
            let matchingBakeries = self.bakeries.filter({ $0.name.lowercased().contains(searchTerm) || $0.formattedAddress.lowercased().contains(searchTerm) })
            
            // Set the value of the filteredBakeries to the results of the filter
            self.filteredBakeries = matchingBakeries
            
         self.tableView.reloadData()
        }
    }
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return bakerySearchBar.text?.isEmpty ?? true
    }

}
