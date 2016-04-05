//
//  Hero.swift
//  HeroesOfTheStormQuickBuild
//
//  Created by Matthias on 31/03/2016.
//

import Foundation
import CoreData

class Hero: NSManagedObject {

    @NSManaged var name: String?
    @NSManaged var iconURL: String?
    @NSManaged var talents: [Talent]

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    convenience init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Hero", inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)

        name = dictionary["name"] as? String
        iconURL = dictionary["iconURL"] as? String
    }
}