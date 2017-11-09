//
//  ASCCountryCodeViewController.swift
//  Documents
//
//  Created by Alexander Yuzhin on 5/10/17.
//  Copyright © 2017 Ascensio System SIA. All rights reserved.
//

import UIKit
import PhoneNumberKit

class ASCCountryCodeViewController: UITableViewController, UISearchControllerDelegate, UISearchResultsUpdating {
    // MARK: - Properties
    
    var selectCountry: ((String, UInt64) -> Void)? = nil
    
    private let phoneNumberKit = PhoneNumberKit()
    private var countries: [String: [[String: Any]]] = [:]
    private var literals: [String] = []
    
    // Search
    private var searchController: UISearchController!
    private var searchBackground: UIView!
    private var searchSeparator: UIView!
    private var searchQuery: String = ""
    
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundView = UIView()
        tableView.tableFooterView = UIView()
        searchBackground = UIView()
        searchSeparator = UIView()
        
        // Prepare data
        fillData()
        
        // Search
        searchController = UISearchController(searchResultsController: nil)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal

        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = true
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.shadowImage = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Private
    
    private func fillData() {
        let allCountries = phoneNumberKit.allCountries()
        var allCountriesSorted: [[String: Any]] = []
        var search: String? = nil
        
        countries.removeAll()
        literals.removeAll()
        
        if let _ = searchController, searchController.isActive {
            if let searchText = searchController.searchBar.text?.trim().lowercased(), searchText.length > 0 {
                search = searchText
            }
        }
        
        for country in allCountries {
            if let countryName = Locale.current.localizedString(forRegionCode: country), let code = phoneNumberKit.countryCode(for: country) {
                if let searchText = search {
                    if let _ = countryName.lowercased().range(of: searchText) {
                        allCountriesSorted.append([
                            "country": countryName,
                            "code": code
                            ])
                    }
                } else {
                    allCountriesSorted.append([
                        "country": countryName,
                        "code": code
                        ])
                }
            }
        }
        
        allCountriesSorted = allCountriesSorted.sorted(by: { ($0["country"] as! String).uppercased() < ($1["country"] as! String).uppercased() })
        
        for country in allCountriesSorted {
            if let countryName = country["country"] as? String {
                let literal = countryName[0].uppercased()
                
                if let _ = countries[literal] {
                    countries[literal]?.append(country)
                } else {
                    countries[literal] = [country]
                    literals.append(literal)
                }
            }
        }
        
        literals = literals.sorted(by: <)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return literals.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return countries[literals[section]]?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return literals[section]
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cellCountryCode", for: indexPath)

        let literal = literals[indexPath.section]
        
        if let info = countries[literal]?[indexPath.row] {
            cell.textLabel?.text = info["country"] as? String ?? ""
            cell.detailTextLabel?.text = "+\(info["code"] as? UInt64 ?? 0)"
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let literal = literals[indexPath.section]
        
        if let info = countries[literal]?[indexPath.row] {
            selectCountry?(info["country"] as? String ?? "", info["code"] as? UInt64 ?? 0)
        }

        searchController?.isActive = false
        self.navigationController?.popViewController(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if index == 0 {
            tableView.contentOffset = CGPoint(x: 0, y: -64)
            return NSNotFound
        }
        
        return index - 1
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        var indexes = literals
        indexes.insert(UITableViewIndexSearch, at: 0)
        return indexes
    }
    
    // MARK: - UISearchController Delegate
    
    func didPresentSearchController(_ searchController: UISearchController) {
        if #available(iOS 11.0, *) {
            //
        } else {
            let statusbarHeight = UIApplication.shared.statusBarFrame.height
            searchBackground.frame = CGRect(x: 0, y: 0, width: searchController.searchBar.frame.size.width, height: searchController.searchBar.frame.size.height + statusbarHeight)
            searchBackground.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            searchBackground.backgroundColor = .white
            searchBackground.alpha = 1
            searchController.view?.insertSubview(searchBackground, at: 0)
            
            searchSeparator.frame = CGRect(x: 0, y: searchController.searchBar.frame.size.height + statusbarHeight, width: searchController.searchBar.frame.size.width, height: 1.0 / UIScreen.main.scale)
            searchSeparator.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
            searchSeparator.backgroundColor = .lightGray
            searchSeparator.alpha = 1
            searchController.view?.insertSubview(searchSeparator, at: 0)
        }
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        searchSeparator.alpha = 0
        searchBackground.alpha = 0
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        fillData()
        tableView.reloadData()
    }
    
    // MARK: - UISearchResults Updating
    
    func updateSearchResults(for searchController: UISearchController) {
        fillData()
        tableView.reloadData()
    }

}
