//
//  HeroesListCollectionViewCell.swift
//  HeroesOfTheStormQuickBuild
//
//  Created by Matthias on 31/03/2016.
//

import UIKit

class HeroesListCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var imageView: UIImageView!

    var imageTask: NSURLSessionTask? {
        didSet {
            oldValue?.cancel()
        }
    }
}