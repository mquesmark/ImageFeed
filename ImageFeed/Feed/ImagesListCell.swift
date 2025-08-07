import UIKit


final class ImagesListCell: UITableViewCell {
    
    let cellImage = UIImageView()
    let cellLike = UIButton()
    let cellDate = UILabel()
    
    static let reuseIdentifier = "ImagesListCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
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
        contentView.addSubview(cellLike)
        contentView.addSubview(cellDate)
    }
    private func setupConstraints() {
        cellImage.translatesAutoresizingMaskIntoConstraints = false
        cellDate.translatesAutoresizingMaskIntoConstraints = false
        cellLike.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cellImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cellImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cellImage.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            cellImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            
            cellDate.bottomAnchor.constraint(equalTo: cellImage.bottomAnchor, constant: -8),
            cellDate.leadingAnchor.constraint(equalTo: cellImage.leadingAnchor, constant: 8),
            cellDate.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor),
            
            cellLike.trailingAnchor.constraint(equalTo: cellImage.trailingAnchor),
            cellLike.topAnchor.constraint(equalTo: cellImage.topAnchor),
        ])
    }
}
