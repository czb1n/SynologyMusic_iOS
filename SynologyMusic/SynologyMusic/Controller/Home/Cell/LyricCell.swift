//
//  LyricCell.swift
//  SynologyMusic
//
//  Created by czb1n on 2022/10/10.
//

import UIKit
import Reusable

class LyricCell: UITableViewCell, NibReusable {

    @IBOutlet var contentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func toPrimaryStyle() {
        self.contentLabel.textColor = ColorName.lyricPrimaryColor.color
        self.contentLabel.font = UIFont.boldSystemFont(ofSize: 18)
    }
    
    func toSecondaryStyle() {
        self.contentLabel.textColor = ColorName.lyricSecondaryColor.color
        self.contentLabel.font = UIFont.systemFont(ofSize: 16)
    }
    
    func toCommonStyle() {
        self.contentLabel.textColor = ColorName.lyricCommonColor.color
        self.contentLabel.font = UIFont.systemFont(ofSize: 14)
    }
}
