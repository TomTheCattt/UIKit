import UIKit

/// A custom UIView that represents the layout and appearance of the side menu.
final class SideMenuView: UIView {
    
    // MARK: - UI Elements
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var settingsLabel: UILabel = {
        let label = UILabel()
        label.text = DefaultValue.String.sideMenuTitle.uppercased()
        label.font = DefaultValue.Fonts.titleFont
        label.textColor = DefaultValue.Colors.accentColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var arrowButton: UIButton = {
        let button = UIButton(type: .system)
        let boldConfig = UIImage.SymbolConfiguration(weight: .bold)
        let image = UIImage(systemName: DefaultValue.Icon.chevronRightIcon, withConfiguration: boldConfig)
        button.setImage(image, for: .normal)
        button.tintColor = DefaultValue.Colors.accentColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var optionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    /// An array of buttons representing the options in the side menu.
    private var optionButtons: [UIButton] = []
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupInitialConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupInitialConstraints()
    }
    
    // MARK: - Setup Methods
    /// Configures the view's appearance and adds subviews.
    private func setupView() {
        backgroundColor = DefaultValue.Colors.sideMenuBackgroundColor
        addSubview(containerView)
        containerView.addSubview(settingsLabel)
        containerView.addSubview(arrowButton)
        containerView.addSubview(optionsStackView)
    }
    
    /// Configures initial constraints for UI elements.
    private func setupInitialConstraints() {
        
        NSLayoutConstraint.activate([
            settingsLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            settingsLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            
            arrowButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            arrowButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 20),
            
            optionsStackView.topAnchor.constraint(equalTo: settingsLabel.bottomAnchor),
            optionsStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])
    }
    
    /// Updates the UI elements for the current device orientation.
    /// - Parameter isLandscape: A Boolean value indicating if the current orientation is landscape.
    func updateUIForCurrentOrientation(isLandscape: Bool) {
        if isLandscape {
            settingsLabel.font = .boldSystemFont(ofSize: DefaultValue.FontSizes.titleFontSize - 2)
            optionButtons.forEach { button in
                button.titleLabel?.font = DefaultValue.Fonts.bodyFont.withSize(DefaultValue.FontSizes.bodyFontSize - 1)
            }
        } else {
            settingsLabel.font = .boldSystemFont(ofSize: DefaultValue.FontSizes.titleFontSize)
            optionButtons.forEach { button in
                button.titleLabel?.font = DefaultValue.Fonts.bodyFont
            }
        }
    }
    
    /// Sets the options for the side menu.
    /// - Parameter options: An array of strings representing the option titles.
    func setOptions(_ options: [String]) {
        optionButtons.forEach { $0.removeFromSuperview() }
        optionButtons = options.map { option in
            let button = UIButton(type: .system)
            button.setTitle(option, for: .normal)
            button.backgroundColor = .clear
            button.titleLabel?.font = DefaultValue.Fonts.bodyFont
            button.setTitleColor(DefaultValue.Colors.accentColor, for: .normal)
            button.contentHorizontalAlignment = .center
            button.translatesAutoresizingMaskIntoConstraints = false
            button.heightAnchor.constraint(equalToConstant: 50).isActive = true
            return button
        }
        
        optionButtons.forEach { optionsStackView.addArrangedSubview($0) }
    }
}
