

import UIKit

protocol FollowerListVCDelegate: AnyObject {
    func didRequestFollowers(for username: String)
}

class FollowerListVC: UIViewController {
    // we use enum cuz they are hasable by default
    enum Section {case main}
        
    
    
    var userName : String!
    var followers: [Follower] = []
    var filteredFollowers: [Follower] = []
    var page = 1
    var hasMoreFollowers = true
    var isSearching = false
    
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, Follower>!

    
    init(username: String) {
        super.init(nibName: nil, bundle: nil)
        self.userName   = username
        title           = username
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
        configureSearchController()
        configureCollectionView()
        getFollowers(username: userName, page: page)
        configureDataSource()
      
       
            
        }
        
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = .systemGreen
       
    }
    
    
    func configureViewController() {
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        navigationItem.rightBarButtonItem = addButton
    }
    

    
    func configureCollectionView() {
        // view.bounds --> mean collectionView will fill up the whole view
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UIHelper.createThreeColumnFlowLayout(in: view))
        view.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.backgroundColor = .systemBackground
        // we use FollowerCell.reuseID insted of actual string cuz we make it static
        collectionView.register(FollowerCell.self, forCellWithReuseIdentifier: FollowerCell.reuseID)
    }
    
    
    
    func configureSearchController() {
        let searchController = UISearchController()
        searchController.searchResultsUpdater  = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder   = "Search for a username"
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController  = searchController
    }
    

    
    
    
    
    func getFollowers(username: String, page: Int) {
        showLoadingView()
        NetworkManager.shared.getFollowers(for: userName, page: page) { [weak self] result in
            guard let self = self else {return}
            self.dismissLoadingView()
            switch result {
            case .success(let followers):
                if followers.count < 100 { self.hasMoreFollowers = false }
                self.followers.append(contentsOf: followers)
                
                if self.followers.isEmpty {
                    let message = "This user doesn't have any followers. Go follow them 😀."
                    DispatchQueue.main.async { self.showEmptyStateView(with: message, in: self.view) }
                    return
                }
                
                self.updateData(on: self.followers)
                
            case .failure(let error):
                self.presentGFAlertOnMainThread(title: "Bad Stuff Happend", message: error.rawValue, buttonTitle: "Ok")
            }
        }
    }
    
    
    
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Follower>(collectionView: collectionView, cellProvider: { (collectionView, indexPath, follower) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FollowerCell.reuseID, for: indexPath) as! FollowerCell
            cell.set(follower: follower)
            return cell
        })
    }
    
    
    func updateData(on followers: [Follower]) {
        // snapshot that represents the UI state
        var snapshot = NSDiffableDataSourceSnapshot<Section, Follower>()
        snapshot.appendSections([.main])
        snapshot.appendItems(followers)
        DispatchQueue.main.async { self.dataSource.apply(snapshot, animatingDifferences: true) }
    }
    
    @objc func addButtonTapped() {
        showLoadingView()
        
        NetworkManager.shared.getUserInfo(for: userName) { [weak self] result in
            guard let self = self else { return }
            self.dismissLoadingView()
            
            switch result {
            case .success(let user):
                let favorite = Follower(login: user.login, avatarUrl: user.avatarUrl)
                
                PersitenceManager.updateWith(favorite: favorite, actionType: .add) { [weak self] error in
                    guard let self = self else { return }
                    
                    guard let error = error else {
                        self.presentGFAlertOnMainThread(title: "Success!", message: "You have successfully favorited this user 🎉", buttonTitle: "Hooray!")
                        return
                    }
                    
                    self.presentGFAlertOnMainThread(title: "Something went wrong", message: error.rawValue, buttonTitle: "Ok")
                }
                
            case .failure(let error):
                self.presentGFAlertOnMainThread(title: "Something went wrong", message: error.rawValue, buttonTitle: "Ok")
            }
        }
    }

}


extension FollowerListVC: UICollectionViewDelegate {
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offsetY         = scrollView.contentOffset.y     /* Current vertical position of the scroll view,(the distance the content has been scrolled). If the content is at the top, this will be 0. If scrolled down, this value increases.*/
        
        let contentHeight   = scrollView.contentSize.height  /*
                                                              Total height of the scrollable content, This is the total height of the content within the scrollView. This includes the height of all items in the collection view, even the ones that are currently off-screen.*/
        
        let height          = scrollView.frame.size.height   /*Height of the visible area of the scroll view(your screen), height:
                                                              This is the visible height of the scroll view (the height of the UICollectionView itself). This is the amount of content the user can see without scrolling.*/
        
        if offsetY > contentHeight - height {
            guard hasMoreFollowers else { return }            // Check if there are more followers to load.
            page += 1                                         // Increment the page number for pagination.
            getFollowers(username: userName, page: page)      // Fetch more followers.
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let activeArray  = isSearching ? filteredFollowers : followers
        let follower     = activeArray[indexPath.item]
        
        let destVC       = UserInfoVC()
        destVC.username  = follower.login
        destVC.delegate = self
        let navController   = UINavigationController(rootViewController: destVC)
        present(navController, animated: true)
    }
}


extension FollowerListVC: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let filter = searchController.searchBar.text, !filter.isEmpty else { return }
        //Uses filter to search for followers whose login (username) contains the search term.
        //lowercased() ensures case-insensitive matching.
        isSearching = true
        filteredFollowers = followers.filter { $0.login.lowercased().contains(filter.lowercased()) }
        updateData(on: filteredFollowers)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearching = false
      // Restores the full list of followers (removes filtering).
        updateData(on: followers)
    }
}
/*
 followers.filter { ... }

 .filter {} is a higher-order function that loops through followers and keeps only the elements that match the given condition.
 It returns a new array (filteredFollowers) containing only the matching followers.
 $0.login.lowercased()

 $0 represents each Follower object inside the loop, represents the item you are on
 $0.login gets the username of the follower.
 .lowercased() converts the username to lowercase (e.g., "JohnDoe" → "johndoe") to make the search case-insensitive.
 
 .contains(filter.lowercased())

 Checks if the lowercased username contains the lowercased search text.
 If "johndoe" contains "jo", it returns true, and that follower remains in the filtered list.
 If "johndoe" does not contain "xyz", it returns false, and that follower is removed.

 */

extension FollowerListVC: FollowerListVCDelegate {
    
    func didRequestFollowers(for username: String) {
        self.userName   = username
        title           = username
        page            = 1
        followers.removeAll()
        filteredFollowers.removeAll()
        // Go to the top of collection view
        collectionView.setContentOffset(.zero, animated: true)
        getFollowers(username: username, page: page)
    }
}
