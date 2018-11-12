//
//  PixelCell.swift
//  PatternRecognizer
//
//  Created by Alexandr Nadtoka on 10/25/18.
//  Copyright © 2018 kreatimont. All rights reserved.
//

import UIKit

class PixelCell: UICollectionViewCell {
    
    static let `identifier` = "pixel-cell"
    
    lazy var label: UILabel = {
        let _label = UILabel()
        _label.font = UIFont.systemFont(ofSize: 8)
        return _label
    }()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.label.text = nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(label)
        label.center = self.center
        
        self.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
