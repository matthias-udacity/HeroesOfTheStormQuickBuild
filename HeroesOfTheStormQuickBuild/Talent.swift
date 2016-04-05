//
//  Talent.swift
//  HeroesOfTheStormQuickBuild
//
//  Created by Matthias on 31/03/2016.
//

import Foundation
import CoreData

class Talent: NSManagedObject {

    @NSManaged var level: NSNumber?
    @NSManaged var name: String?
    @NSManaged var iconURL: String?
    @NSManaged var hero: Hero?

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    convenience init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Talent", inManagedObjectContext: context)!
        self.init(entity: entity, insertIntoManagedObjectContext: context)

        level = dictionary["level"] as? Int
        name = dictionary["name"] as? String
        iconURL = dictionary["iconURL"] as? String
    }
}