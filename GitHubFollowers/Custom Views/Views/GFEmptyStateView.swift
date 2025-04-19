


import UIKit

class GFEmptyStateView: UIView {
    
    let messageLabel    = GFTitleLabel(textAligment: .center, fontSize: 28)
    let logoImageView   = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    init(message: String) {
        /*
         Why Use .zero?
         .zero is shorthand for CGRect(x: 0, y: 0, width: 0, height: 0), meaning the view starts with no size.
         The actual size will be set later using Auto Layout constraints, so there's no need to define a specific frame now.
         */
        super.init(frame: .zero)
        messageLabel.text = message
        configure()
    }
    
    
    private func configure() {
        addSubview(messageLabel)
        addSubview(logoImageView)
        
        messageLabel.numberOfLines = 3
        messageLabel.textColor  = .secondaryLabel // Uses .secondaryLabel color for a muted text appearance.
        
        logoImageView.image = UIImage(named: "empty-state-logo")
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -150),
            messageLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 40),
            messageLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -40),
            messageLabel.heightAnchor.constraint(equalToConstant: 200),
            // Sets logoImageView's width and height to be 1.3x the view’s width.
            logoImageView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1.3),
            logoImageView.heightAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1.3),
            // Positions the image partially outside the screen (trailing = 170, bottom = 40), creating a visual effect.
            logoImageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 170),
            logoImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 40)
        ])
    }
}
