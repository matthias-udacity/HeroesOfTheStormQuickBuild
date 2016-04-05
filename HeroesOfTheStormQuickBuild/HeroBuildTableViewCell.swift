//
//  HeroesListTableViewCell.swift
//  HeroesOfTheStormQuickBuild
//
//  Created by Matthias on 31/03/2016.
//

import UIKit

class HeroBuildTableViewCell: UITableViewCell {

    @IBOutlet weak var talentIconActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var talentIconImageView: UIImageView!
    @IBOutlet weak var talentNameLabel: UILabel!

    var imageTask: NSURLSessionTask? {
        didSet {
            oldValue?.cancel()
        }
    }
}