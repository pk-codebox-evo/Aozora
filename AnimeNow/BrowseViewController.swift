//
//  DiscoverViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/23/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit
import ANParseKit
import Parse

enum BrowseType: String {
    case TopAnime = "Top Anime"
    case TopAiring = "Top Airing"
    case TopUpcoming = "Top Upcoming"
    case TopTVSeries = "Top TV Series"
    case TopMovies = "Top Movies"
    case TopOVA = "Top OVA"
    case TopSpecials = "Top Specials"
    case JustAdded = "Just Added"
    case MostPopular = "Most Popular"
    case Filtering = "Filtering"
    
    static func allItems() -> [String] {
        return [
            BrowseType.TopAnime.rawValue,
            BrowseType.TopAiring.rawValue,
            BrowseType.TopUpcoming.rawValue,
            BrowseType.TopTVSeries.rawValue,
            BrowseType.TopMovies.rawValue,
            BrowseType.TopOVA.rawValue,
            BrowseType.TopSpecials.rawValue,
            BrowseType.JustAdded.rawValue,
            BrowseType.MostPopular.rawValue,
        ]
    }
}

class BrowseViewController: UIViewController {
    
    var currentBrowseType: BrowseType = .TopAnime
    var dataSource: [Anime] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    var loadingView: LoaderView!
    var currentConfiguration: Configuration =
    [
        (FilterSection.Sort, SortBy.Rating.rawValue, SortBy.allRawValues()),
        (FilterSection.FilterTitle, nil, []),
        (FilterSection.AnimeType, nil, AnimeType.allRawValues()),
        (FilterSection.Year, nil, allYears),
        (FilterSection.Status, nil, AnimeStatus.allRawValues()),
        (FilterSection.Studio, nil, allStudios.sorted({$0.localizedCaseInsensitiveCompare($1) == NSComparisonResult.OrderedAscending})),
        (FilterSection.Classification, nil, AnimeClassification.allRawValues()),
        (FilterSection.Genres, nil, AnimeGenre.allRawValues())
    ]
    var selectedGenres: [String] = []
    
    @IBOutlet weak var navigationBarTitle: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let chartNib = UINib(nibName: "AnimeCell", bundle: nil)
        collectionView.registerNib(chartNib, forCellWithReuseIdentifier: "AnimeCell")
        let posterNib = UINib(nibName: "AnimeCellPoster", bundle: nil)
        collectionView.registerNib(chartNib, forCellWithReuseIdentifier: "AnimeCellPoster")
        let listNib = UINib(nibName: "AnimeCellList", bundle: nil)
        collectionView.registerNib(chartNib, forCellWithReuseIdentifier: "AnimeCellList")
        
        // TODO: Remove duplicated code in BaseViewController..
        var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "changeSeasonalChart")
        navigationController?.navigationBar.addGestureRecognizer(tapGestureRecognizer)
        
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: view.bounds.size.width, height: 132)
        
        loadingView = LoaderView(parentView: self.view)
        
        fetchListType(currentBrowseType)
    }
    
    func fetchListType(type: BrowseType, customQuery: PFQuery? = nil) {
        
        // Animate
        collectionView.animateFadeOut()
        loadingView.startAnimating()
        
        // Update model
        currentBrowseType = type
        
        // Update UI
        collectionView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
        navigationBarTitle.text! = currentBrowseType.rawValue + " " + FontAwesome.AngleDown.rawValue
        
        // Fetch
        var query = Anime.query()!
        
        switch currentBrowseType {
        case .TopAnime:
            query
            .orderByAscending("rank")
        case .TopAiring:
            query
            .orderByAscending("rank")
            .whereKey("status", equalTo: AnimeStatus.CurrentlyAiring.rawValue)
        case .TopUpcoming:
            query.orderByAscending("rank")
            .whereKey("status", equalTo: AnimeStatus.NotYetAired.rawValue)
        case .TopTVSeries:
            query.orderByAscending("rank")
            .whereKey("type", equalTo: AnimeType.TV.rawValue)
        case .TopMovies:
            query.orderByAscending("rank")
            .whereKey("type", equalTo: AnimeType.Movie.rawValue)
        case .TopOVA:
            query.orderByAscending("rank")
            .whereKey("type", equalTo: AnimeType.OVA.rawValue)
        case .TopSpecials:
            query.orderByAscending("rank")
            .whereKey("type", equalTo: AnimeType.Special.rawValue)
        case .JustAdded:
            query.orderByDescending("createdAt")
        case .MostPopular:
            query.orderByAscending("popularityRank")
        case .Filtering:
            if let customQuery = customQuery {
                query = customQuery
            }
        }
        
        
        query.findObjectsInBackgroundWithBlock { (result, error) -> Void in
            if result != nil {
                self.dataSource = result as! [Anime]
            }
            self.loadingView.stopAnimating()
            self.collectionView.animateFadeIn()
        }
    }
    
    func changeSeasonalChart() {
        if let bar = navigationController?.navigationBar {         
            DropDownListViewController.showDropDownListWith(sender: bar, viewController: tabBarController!, delegate: self, dataSource: [BrowseType.allItems()])
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func presentSearchPressed(sender: AnyObject) {
        
        if let tabBar = tabBarController {
            let controller = UIStoryboard(name: "Browse", bundle: nil).instantiateViewControllerWithIdentifier("Search") as! SearchViewController
            controller.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
            controller.modalPresentationStyle = .OverCurrentContext
            tabBar.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    @IBAction func showFilterPressed(sender: AnyObject) {
        
        if let tabBar = tabBarController {
            let controller = UIStoryboard(name: "Browse", bundle: nil).instantiateViewControllerWithIdentifier("Filter") as! FilterViewController
            
            controller.delegate = self
            controller.initWith(configuration: currentConfiguration)
            controller.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
            controller.modalPresentationStyle = .OverCurrentContext
            tabBar.presentViewController(controller, animated: true, completion: nil)
        }
        
    }
}


extension BrowseViewController: UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("AnimeCell", forIndexPath: indexPath) as! AnimeCell
        
        let anime = dataSource[indexPath.row]
        
        cell.configureWithAnime(anime)
        
        return cell
    }
}

extension BrowseViewController: UICollectionViewDelegate {
    
}

extension BrowseViewController: FilterViewControllerDelegate {
    func finishedWith(#configuration: Configuration, selectedGenres: [String]) {
        
        currentConfiguration = configuration
        self.selectedGenres = selectedGenres
        
        let query = Anime.query()!
        
        for (filterSection, value, _) in configuration {
            if let value = value {
                switch filterSection {
                case .Sort:
                    switch SortBy(rawValue: value)! {
                    case .Rating:
                        query.orderByAscending("rank")
                    case .Popularity:
                        query.orderByAscending("popularityRank")
                    case .Title:
                        query.orderByAscending("title")
                    default: break
                    }
                case .AnimeType:
                    query.whereKey("type", equalTo: value)
                case .Year:
                    query.whereKey("year", equalTo: value.toInt()!)
                case .Status:
                    query.whereKey("status", equalTo: value)
                case .Studio:
                    query.whereKey("producers", containedIn: [value])
                case .Classification:
                    let subquery = AnimeDetail.query()!
                    subquery.whereKey("classification", equalTo: value)
                    query.whereKey("details", matchesQuery: subquery)
                default: break;
                }
            }
        }
        
        if selectedGenres.count != 0 {
            query.whereKey("genres", containsAllObjectsInArray: selectedGenres)
        }
        
        
        fetchListType(BrowseType.Filtering, customQuery: query)
    }
}


extension BrowseViewController: DropDownListDelegate {
    func selectedAction(trigger: UIView, action: String, indexPath: NSIndexPath) {
        let rawValue = BrowseType.allItems()[indexPath.row]
        fetchListType(BrowseType(rawValue: rawValue)!)
    }
}

var allYears = ["2016","2015","2014","2013","2012","2011","2010","2009","2008","2007","2006","2005","2004","2003","2002","2001","2000","1999","1998","1997","1996","1995","1994","1993","1992","1991","1990","1989","1988","1987","1986","1985","1984","1983","1982","1981","1980","1979","1978","1977","1976","1975","1974","1973","1972","1971","1970"]

var allStudios = ["P.A. Works", "Ordet", "Studio Khara", "Sega", "Production I.G", "Studio 4C", "Creators in Pack TOKYO", "Shirogumi", "Satelight", "Genco", "Kinema Citrus", "ufotable", "Artmic", "POLYGON PICTURES", "Lay-duce", "DAX Production", "Passione", "AIC A.S.T.A.", "office DCI", "Benesse Corporation", "NAZ", "Silver Link", "Gonzo", "AIC Plus+", "Media Factory", "DropWave", "Toho Company", "Production IMS", "Manglobe", "TYO Animations", "J.C. Staff", "Actas", "Brains Base", "Wit Studio", "Ultra Super Pictures", "Kenji Studio", "Kachidoki Studio", "Nomad", "TROYCA", "Studio 3Hz", "Seven Arcs", "Studio Deva Loka", "Arms", "Hoods Entertainment", "CoMix Wave", "Kyoto Animation", "Nippon Ichi Software", "Sunrise", "MAPPA", "Studio Deen", "Studio Unicorn", "Gathering", "Madhouse", "Tatsunoko Productions", "TNK", "Ascension", "Bridge", "Toei Animation", "Project No.9", "Trigger", "Nippon Animation", "Studio Colorido", "Diomedea", "Xebec", "SANZIGEN", "A-1 Pictures", "C-Station", "TMS Entertainment", "Studio Shuka", "Fanworks", "Encourage Films", "Studio Pierrot", "C2C", "Studio Gokumi", "Asahi Production", "AIC", "Fuji TV", "GoHands", "Oriental Light and Magic", "Poncotan", "Shogakukan Productions", "Studio Chizu", "Aniplex", "Telecom Animation Film", "Graphinica", "Trick Block", "VAP", "Bones", "Tezuka Productions", "Feel", "8bit", "Nexus", "Studio Gallop", "Gainax", "Dogakobo", "LIDEN FILMS", "DLE", "SynergySP", "Shaft", "Shin-Ei Animation", "White Fox", "David Production", "Zexcs", "Seven", "Anpro", "TV Tokyo", "Lerche", "Strawberry Meets Pictures", "Studio Ghibli", "Artland"]

// Madhouse Studios -> Madhouse