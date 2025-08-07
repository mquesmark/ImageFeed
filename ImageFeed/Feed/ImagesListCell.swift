import UIKit


final class ImagesListCell: UITableViewCell {
    
    let cellImage = UIImageView()
    let cellLike = UIButton()
    let cellDate = UILabel()
    let gradientOverlay = UIView()
    
    static let reuseIdentifier = "ImagesListCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraintsAndVisuals()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cellImage.image = nil
    }
    
    private func setupViews() {
        contentView.addSubview(cellImage)
        contentView.addSubview(gradientOverlay)
        contentView.addSubview(cellLike)
        contentView.addSubview(cellDate)
    }
    private func setupConstraintsAndVisuals() {
        cellImage.translatesAutoresizingMaskIntoConstraints = false
        cellDate.translatesAutoresizingMaskIntoConstraints = false
        cellLike.translatesAutoresizingMaskIntoConstraints = false
        gradientOverlay.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = UIColor.ypBlackIOS
        self.selectionStyle = .none
        contentView.backgroundColor = .ypBlackIOS
        cellImage.layer.cornerRadius = 16
        cellImage.layer.masksToBounds = true

        let gradient = makeBottomOverlayGradient()
        gradientOverlay.layer.insertSublayer(gradient, at: 0)

        cellDate.textColor = .ypWhiteIOS
        cellDate.font = .systemFont(ofSize: 13)
        cellDate.layer.shadowColor = UIColor.ypBlackIOS.cgColor
        
        NSLayoutConstraint.activate([
            cellImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cellImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cellImage.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            cellImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            
            gradientOverlay.leadingAnchor.constraint(equalTo: cellImage.leadingAnchor),
            gradientOverlay.trailingAnchor.constraint(equalTo: cellImage.trailingAnchor),
            gradientOverlay.bottomAnchor.constraint(equalTo: cellImage.bottomAnchor),
            gradientOverlay.heightAnchor.constraint(equalToConstant: 30),
            
            cellDate.bottomAnchor.constraint(equalTo: gradientOverlay.bottomAnchor, constant: -8),
            cellDate.leadingAnchor.constraint(equalTo: cellImage.leadingAnchor, constant: 8),
            cellDate.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            
            cellLike.trailingAnchor.constraint(equalTo: cellImage.trailingAnchor),
            cellLike.topAnchor.constraint(equalTo: cellImage.topAnchor),
        ])
    }
    
    private func makeBottomOverlayGradient() -> CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.102, green: 0.106, blue: 0.133, alpha: 0).cgColor,
            UIColor(red: 0.102, green: 0.106, blue: 0.133, alpha: 1).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 32, height: 30)
        return gradient
    }
}
