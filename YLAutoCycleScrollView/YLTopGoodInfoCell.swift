//
//  YLTopGoodInfoCell.swift
//  MysteryBox
//
//  Created by AlbertYuan on 2021/11/23.
//

import UIKit

class YLTopGoodInfoCell: UICollectionViewCell {

    @IBOutlet weak var textLabel: UILabel!

    var textStr :String = "" {
        didSet{
            textLabel.text = textStr
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
