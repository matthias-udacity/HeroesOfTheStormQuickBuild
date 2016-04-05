//
//  HeroesListViewController.swift
//  HeroesOfTheStormQuickBuild
//
//  Created by Matthias on 31/03/2016.
//

import UIKit
import CoreData

class HeroesListViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {

    let hotsLogsClient = HOTSLogsClient()
    let imageCache = ImageCache()

    var pendingInserts = [NSIndexPath]()
    var pendingDeletes = [NSIndexPath]()

    @IBOutlet weak var refreshBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var heroesListCollectionView: UICollectionView!

    func updateHeroesList() {
        // Disable refresh button.
        refreshBarButtonItem.enabled = false

        let updateHeroesListTask = hotsLogsClient.taskForHeroesList() { heroesList, error in
            // Hide network activity indicator.
            (UIApplication.sharedApplication().delegate as! AppDelegate).setNetworkActivity(false)

            // Display error or process results.
            dispatch_async(dispatch_get_main_queue()) {
                if let error = error {
                    self.showError(error)
                } else if let heroesList = heroesList {
                    let fetchedObjects = self.fetchedResultsController.fetchedObjects!

                    // Merge list of heroes into CoreData.
                    for heroDictionary in heroesList {
                        if fetchedObjects.indexOf({ $0.name == heroDictionary["name"] as! String }) == nil {
                            _ = Hero(dictionary: heroDictionary, context: (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext)
                        }
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
        updateHeroesListTask.resume()
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        // Fetch heroes using NSFetchedResultsController.
        do {
            fetchedResultsController.delegate = self
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            showError(error)
        }

        // Update hero list if there are no heroes.
        if fetchedResultsController.fetchedObjects?.count == 0 {
            updateHeroesList()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showHeroBuildSegue" {
            if let controller = segue.destinationViewController as? HeroBuildViewController {
                controller.hero = sender as! Hero
            }
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
        updateHeroesList()
    }

    // MARK: - NSFetchedResultsController

    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Hero")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
    }()

    // MARK: - NSFetchedResultsControllerDelegate

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.heroesListCollectionView!.performBatchUpdates({
            if !self.pendingInserts.isEmpty {
                self.heroesListCollectionView.insertItemsAtIndexPaths(self.pendingInserts)
            }
            if !self.pendingDeletes.isEmpty {
                self.heroesListCollectionView.deleteItemsAtIndexPaths(self.pendingDeletes)
            }
        }, completion: { finished in
            self.pendingInserts.removeAll(keepCapacity: false)
            self.pendingDeletes.removeAll(keepCapacity: false)
        })
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            pendingInserts.append(newIndexPath!)
        case .Delete:
            pendingDeletes.append(indexPath!)
        default:
            break
        }
    }

    // MARK: - UITableViewDataSource

    func configureCell(cell: HeroesListCollectionViewCell, hero: Hero) {
        let heroIconURL = NSURL(string: hero.iconURL!)!

        // Configure hero icon.
        let imageIdentifier = heroIconURL.pathComponents!.dropFirst().joinWithSeparator("_")

        if let image = imageCache.loadImageWithIdentifier(imageIdentifier) {
            cell.imageView!.image = image

            // Show image instead of activity indicator.
            cell.imageView!.hidden = false
            cell.activityIndicatorView.stopAnimating()
        } else {
            // Show activity indicator instead of image.
            cell.imageView!.hidden = true
            cell.activityIndicatorView.startAnimating()

            let task = hotsLogsClient.taskForImageWithURL(heroIconURL) { data, error in
                // Hide network activity indicator.
                (UIApplication.sharedApplication().delegate as! AppDelegate).setNetworkActivity(false)

                if data != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        if let image = UIImage(data: data!) {
                            cell.imageView!.image = image

                            // Show image instead of activity indicator.
                            cell.imageView!.hidden = false
                            cell.activityIndicatorView.stopAnimating()

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

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let hero = fetchedResultsController.objectAtIndexPath(indexPath) as! Hero

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("heroesListCollectionViewCell", forIndexPath: indexPath) as! HeroesListCollectionViewCell
        configureCell(cell, hero: hero)

        return cell
    }

    // MARK: - UITableViewDelegate

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let hero = fetchedResultsController.objectAtIndexPath(indexPath) as! Hero
        performSegueWithIdentifier("showHeroBuildSegue", sender: hero)
    }
}