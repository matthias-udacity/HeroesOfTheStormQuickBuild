//
//  HeroBuildViewController.swift
//  HeroesOfTheStormQuickBuild
//
//  Created by Matthias on 31/03/2016.
//

import UIKit
import CoreData

class HeroBuildViewController: UIViewController, UITableViewDataSource, NSFetchedResultsControllerDelegate {

    let hotsLogsClient = HOTSLogsClient()
    let imageCache = ImageCache()

    var hero: Hero!
    var heroBuild: [[String: AnyObject]]?
    
    @IBOutlet weak var refreshBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var heroBuildTableView: UITableView!

    func updateHeroBuild() {
        // Disable refresh button.
        refreshBarButtonItem.enabled = false

        let updateHeroBuildTask = hotsLogsClient.taskForHeroBuild(hero.name!) { heroBuild, error in
            // Hide network activity indicator.
            (UIApplication.sharedApplication().delegate as! AppDelegate).setNetworkActivity(false)

            // Display error or process results.
            dispatch_async(dispatch_get_main_queue()) {
                if let error = error {
                    self.showError(error)
                } else if let heroBuild = heroBuild {
                    let fetchedObjects = self.fetchedResultsController.fetchedObjects!

                    // Delete previous talents.
                    for talent in fetchedObjects as! [Talent] {
                        (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext.deleteObject(talent)
                    }

                    // Insert list of talents into CoreData.
                    for talentDictionary in heroBuild {
                        let talent = Talent(dictionary: talentDictionary, context: (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext)
                        talent.hero = self.hero
                    }

                    // Save to CoreData.
                    (UIApplication.sharedApplication().delegate as! AppDelegate).saveContext()
                }

                // Enable refresh button.
                self.refreshBarButtonItem.enabled = true
            }
        }

        // Display network activity indicator.
        (UIApplication.sharedApplication().delegate as! AppDelegate).setNetworkActivity(true)

        // Start update task.
        updateHeroBuildTask.resume()
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        // Update title.
        if let name = hero.name {
            title = name + " Build"
        } else {
            title = "Build"
        }

        // Fetch talents using NSFetchedResultsController.
        do {
            fetchedResultsController.delegate = self
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            showError(error)
        }

        // Update talent list if there are no talents.
        if fetchedResultsController.fetchedObjects?.count == 0 {
            updateHeroBuild()
        }
    }

    // MARK: - UIAlertController

    private func showError(error: NSError) {
        let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    // MARK: - IBActions

    @IBAction func refreshAction(sender: AnyObject) {
        updateHeroBuild()
    }

    // MARK: - NSFetchedResultsController

    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Talent")
        fetchRequest.predicate = NSPredicate(format: "hero == %@", self.hero)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "level", ascending: true)]

        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    }()

    // MARK: NSFetchedResultsControllerDelegate

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        heroBuildTableView.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            heroBuildTableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)

        case .Delete:
            heroBuildTableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)

        case .Update:
            let talent = fetchedResultsController.objectAtIndexPath(indexPath!) as! Talent

            let cell = heroBuildTableView.cellForRowAtIndexPath(indexPath!) as! HeroBuildTableViewCell
            configureCell(cell, talent: talent)

        case .Move:
            heroBuildTableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            heroBuildTableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        heroBuildTableView.endUpdates()
    }

    // MARK: - UITableViewDataSource

    func configureCell(cell: HeroBuildTableViewCell, talent: Talent) {
        let talentIconURL = NSURL(string: talent.iconURL!)!

        // Configure talent name.
        if var name = talent.name {
            // HTML decode talent name.
            let attributedOptions: [String: AnyObject] = [
                NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
            ]

            do {
                name = try NSAttributedString(data: name.dataUsingEncoding(NSUTF8StringEncoding)!, options: attributedOptions, documentAttributes: nil).string
            } catch {}

            // Split string into talent name and talent
            cell.talentNameLabel.text = name.componentsSeparatedByString(": ").first!
        }

        // Configure talent icon.
        let imageIdentifier = talentIconURL.pathComponents!.dropFirst().joinWithSeparator("_")

        if let image = imageCache.loadImageWithIdentifier(imageIdentifier) {
            cell.talentIconImageView.image = image

            // Show image instead of activity indicator.
            cell.talentIconImageView.hidden = false
            cell.talentIconActivityIndicatorView.stopAnimating()
        } else {
            // Show activity indicator instead of image.
            cell.talentIconImageView.hidden = true
            cell.talentIconActivityIndicatorView.startAnimating()

            let task = hotsLogsClient.taskForImageWithURL(talentIconURL) { data, error in
                // Hide network activity indicator.
                (UIApplication.sharedApplication().delegate as! AppDelegate).setNetworkActivity(false)

                if data != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        if let image = UIImage(data: data!) {
                            cell.talentIconImageView.image = image

                            // Show image instead of activity indicator.
                            cell.talentIconImageView.hidden = false
                            cell.talentIconActivityIndicatorView.stopAnimating()

                            // Store image in cache.
                            self.imageCache.storageImageWithIdentifier(image, identifier: imageIdentifier)
                        }
                    }
                }
            }

            // Display network activity indicator.
            (UIApplication.sharedApplication().delegate as! AppDelegate).setNetworkActivity(true)

            // Start download task.
            task.resume()
            cell.imageTask = task
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let talent = fetchedResultsController.objectAtIndexPath(indexPath) as! Talent

        let cell = tableView.dequeueReusableCellWithIdentifier("heroBuildTableViewCell", forIndexPath: indexPath) as! HeroBuildTableViewCell
        configureCell(cell, talent: talent)

        return cell
    }
}