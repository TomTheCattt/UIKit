import UIKit
import Photos
class HomeViewController: UIViewController {
    private let homeView = HomeView()
    private let sideMenuView = SideMenuView()
    weak var homeViewDelegate: HomeViewDelegate?
    
    private var menuWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return isPortrait ? screenWidth * 0.8 : screenWidth * 0.4
    }
    private var isPortrait: Bool {
        return UIDevice.current.orientation.isPortrait || UIDevice.current.orientation == .unknown
    }
    
    private var menuState: MenuState = .closed
    private var sideMenuLeadingConstraint: NSLayoutConstraint!
    
    private enum MenuState {
        case opened, closed
    }
    
    private lazy var dataManager: DataManager = {
        return DataManager(context: CoreDataManager.shared.context, mediaType: nil)
    }()
    
    var loadingState: LoadingState = .idle {
        didSet {
            loadingStateDidChange?(loadingState)
        }
    }
    
    var loadingStateDidChange: ((LoadingState) -> Void)?
    
    private lazy var blurView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapBlurView))
        view.addGestureRecognizer(tapGesture)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        homeView.delegate = self
        sideMenuView.delegate = self
        setupViews()
        setupBlurView()
        setupSideMenuView()
        setupConstraints()
    }
    
    private func setupBlurView() {
        view.addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupSideMenuView() {
        sideMenuView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sideMenuView)
        view.bringSubviewToFront(sideMenuView)
    }
    
    private func setupViews() {
        homeView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(homeView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            homeView.topAnchor.constraint(equalTo: view.topAnchor),
            homeView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            homeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            homeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            
            sideMenuView.topAnchor.constraint(equalTo: view.topAnchor),
            sideMenuView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sideMenuView.widthAnchor.constraint(equalToConstant: menuWidth)
        ])
        
        // Set the side menu initially off the screen to the left
        sideMenuLeadingConstraint = sideMenuView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -menuWidth)
        sideMenuLeadingConstraint.isActive = true
    }
    
    private func toggleMenu(shouldOpen: Bool) {
        menuState = shouldOpen ? .opened : .closed
        sideMenuLeadingConstraint.constant = shouldOpen ? 0 : -menuWidth
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
            self.blurView.alpha = shouldOpen ? 1 : 0  // Show or hide blur
        }
    }
    
    @objc private func didTapBlurView() {
        toggleMenu(shouldOpen: false)  // Close menu when blur is tapped
    }
}

extension HomeViewController {
    private func fetchData() {
        loadingState = .loading(progress: 0)
        let fetchOptions = PHFetchOptions()
        let imageAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let videoAssets = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        
        var allAssets: [PHAsset] = []
        imageAssets.enumerateObjects { (asset, _, _) in
            allAssets.append(asset)
        }
        videoAssets.enumerateObjects { (asset, _, _) in
            allAssets.append(asset)
        }
        
        dataManager.saveMediaFromAssets(allAssets) { processed, total in
            let progress = Float(processed) / Float(total)
            self.loadingState = .loading(progress: progress)
        } completion: { result in
            switch result {
            case .success(let completion):
                self.loadingState = .completed(updated: completion.totalProcessed,
                                               skipped: completion.totalSkipped)
                homeViewDelegate?.homeViewDidFinishFetching(result)
                
            case .failure(let error):
                self.loadingState = .error(error.localizedDescription)
            }
        }
    }
}

extension HomeViewController: HomeViewDelegate {
    func homeViewDidTapMenu() {
        toggleMenu(shouldOpen: menuState == .closed)
    }
    
    func homeView(didSelectCategory category: CategoryType) {
        let listViewController = ListViewController()
        listViewController.category = category
        //listViewController.delegate = self
        navigationController?.pushViewController(listViewController, animated: true)
    }
}

extension HomeViewController: SideMenuViewDelegate {
    func closeButtonTapped() {
        toggleMenu(shouldOpen: false)
    }
}
