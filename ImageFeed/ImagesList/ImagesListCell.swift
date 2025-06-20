import UIKit


final class ImagesListCell: UITableViewCell {
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellLike: UIButton!
    @IBOutlet weak var cellDate: UILabel!
    
    static let reuseIdentifier = "ImagesListCell"
}
