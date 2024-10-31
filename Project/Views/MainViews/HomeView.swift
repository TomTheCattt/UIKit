import UIKit

/// A custom UIView that represents the layout and appearance of the home view.
class HomeView: UIView {

    // MARK: - UI Element(s)
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = DefaultValue.Colors.secondaryColor
        return tableView
    }()
    
    let loadingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.isHidden = true
        return view
    }()
    
    let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        return indicator
    }()
    
    lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.isHidden = true
        return progress
    }()
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupConstraints()
    }
    
    // MARK: - Setup Methods
    /// Configures the view's appearance and adds subviews.
    private func setupView() {
        addSubview(tableView)
        addSubview(loadingView)
        loadingView.addSubview(activityIndicator)
        loadingView.addSubview(progressView)
        
        // Set the background color
        backgroundColor = DefaultValue.Colors.primaryColor
        
        // Configure tableView
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = nil
        tableView.dataSource = nil
        
        // Configure loadingView
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set up loadingView's appearance
        loadingView.isHidden = true
    }
    
    /// Configures constraints for UI elements.
    private func setupConstraints() {
        // Table view constraints
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        // Loading view constraints
        NSLayoutConstraint.activate([
            loadingView.topAnchor.constraint(equalTo: topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor),
            
            progressView.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            progressView.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            progressView.widthAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    /// Shows or hides the loading view and activity indicator.
    /// - Parameter show: A Boolean value indicating whether to show or hide the loading view.
    func showLoading(_ show: Bool) {
        loadingView.isHidden = !show
        if show {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
}
