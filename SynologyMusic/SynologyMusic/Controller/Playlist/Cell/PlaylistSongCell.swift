//
//  PlaylistSongCell.swift
//  SynologyMusic
//
//  Created by czb1n on 2022/9/29.
//

import UIKit
import Reusable

class PlaylistSongCell: UITableViewCell, NibReusable {
    
    @IBOutlet var noLabel: UILabel!
    @IBOutlet var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
