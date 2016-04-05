//
//  HOTSLogsClient.swift
//  HeroesOfTheStormQuickBuild
//
//  Created by Matthias on 31/03/2016.
//

import Foundation

class HOTSLogsClient {

    let heroesListURL = NSURL(string: "http://www.hotslogs.com/")!
    let heroesListPattern = try! NSRegularExpression(pattern: "<td[^>]*><img [^>]*src=\"([^\"]+)\"[^>]*></td><td[^>]*><a [^>]*href=\"([^\"]+)\"[^>]*>([^<]*)</a></td><td[^>]*>([^<]*)</td><td[^>]*>([^<]*)</td><td[^>]*>([^<]*)</td>", options: NSRegularExpressionOptions.CaseInsensitive)

    let heroBuildURL = NSURL(string: "http://www.hotslogs.com/Sitewide/HeroDetails")!
    let heroBuildPattern = try! NSRegularExpression(pattern: "<td>(\\d+)</td><td[^>]*>[^<]*</td><td[^>]*><img [^>]*title=\"([^\"]+)\" [^>]*src=\"([^\"]+)\"[^>]*></td><td[^>]*><img [^>]*title=\"([^\"]+)\" [^>]*src=\"([^\"]+)\"[^>]*></td><td[^>]*><img [^>]*title=\"([^\"]+)\" [^>]*src=\"([^\"]+)\"[^>]*></td><td[^>]*><img [^>]*title=\"([^\"]+)\" [^>]*src=\"([^\"]+)\"[^>]*></td><td[^>]*><img [^>]*title=\"([^\"]+)\" [^>]*src=\"([^\"]+)\"[^>]*></td><td[^>]*><img [^>]*title=\"([^\"]+)\" [^>]*src=\"([^\"]+)\"[^>]*></td><td[^>]*><img [^>]*title=\"([^\"]+)\" [^>]*src=\"([^\"]+)\"[^>]*></td>", options: NSRegularExpressionOptions.CaseInsensitive)

    // MARK: - Heroes List

    func taskForHeroesList(completionHandler: (heroesList: [[String: AnyObject]]?, error: NSError?) -> Void) -> NSURLSessionDataTask {
        return NSURLSession.sharedSession().dataTaskWithURL(heroesListURL) { data, response, error in
            if error != nil {
                completionHandler(heroesList: nil, error: error)
            } else {
                self.parseHeroesList(String(data: data!, encoding: NSUTF8StringEncoding)!, response: response!, completionHandler: completionHandler)
            }
        }
    }

    private func parseHeroesList(heroesListPage: String, response: NSURLResponse, completionHandler: (heroesList: [[String: AnyObject]]?, error: NSError?) -> Void) {
        var heroesList = [[String: AnyObject]]()

        heroesListPattern.enumerateMatchesInString(heroesListPage, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, heroesListPage.characters.count)) { result, flags, stop in
            heroesList.append([
                "iconURL": self.extractURLString(heroesListPage, response: response, range: result!.rangeAtIndex(1))!,
                "name":    self.extractString(heroesListPage, response: response, range: result!.rangeAtIndex(3))
            ])
        }

        if heroesList.isEmpty {
            completionHandler(heroesList: nil, error: NSError(domain: "Unable to extract list of heroes from \(response.URL!), the site may be temporarily unavailable", code: 0, userInfo: nil))
        } else {
            completionHandler(heroesList: heroesList, error: nil)
        }
    }

    // MARK: - Hero Build

    func taskForHeroBuild(hero: String, completionHandler: (heroBuild: [[String: AnyObject]]?, error: NSError?) -> Void) -> NSURLSessionDataTask {
        let components = NSURLComponents.init(URL: heroBuildURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [NSURLQueryItem.init(name: "Hero", value: hero)]

        return NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: components.URL!)) { data, response, error in
            if error != nil {
                completionHandler(heroBuild: nil, error: error)
            } else {
                self.parseHeroBuild(String(data: data!, encoding: NSUTF8StringEncoding)!, response: response!, completionHandler: completionHandler)
            }
        }
    }

    private func parseHeroBuild(heroBuildPage: String, response: NSURLResponse, completionHandler: (heroBuild: [[String: AnyObject]]?, error: NSError?) -> Void) {
        var heroBuilds = [[String: AnyObject]]()

        // Extract all popular talent builds.
        heroBuildPattern.enumerateMatchesInString(heroBuildPage, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, heroBuildPage.characters.count)) { result, flags, stop in
            heroBuilds.append([
                "gamesPlayed":       self.extractInteger(heroBuildPage, response: response, range: result!.rangeAtIndex(1)) ?? 0,
                "talentLevel1Name":  self.extractString(heroBuildPage, response: response, range: result!.rangeAtIndex(2)),
                "talentLevel1Icon":  self.extractURLString(heroBuildPage, response: response, range: result!.rangeAtIndex(3))!,
                "talentLevel4Name":  self.extractString(heroBuildPage, response: response, range: result!.rangeAtIndex(4)),
                "talentLevel4Icon":  self.extractURLString(heroBuildPage, response: response, range: result!.rangeAtIndex(5))!,
                "talentLevel7Name":  self.extractString(heroBuildPage, response: response, range: result!.rangeAtIndex(6)),
                "talentLevel7Icon":  self.extractURLString(heroBuildPage, response: response, range: result!.rangeAtIndex(7))!,
                "talentLevel10Name": self.extractString(heroBuildPage, response: response, range: result!.rangeAtIndex(8)),
                "talentLevel10Icon": self.extractURLString(heroBuildPage, response: response, range: result!.rangeAtIndex(9))!,
                "talentLevel13Name": self.extractString(heroBuildPage, response: response, range: result!.rangeAtIndex(10)),
                "talentLevel13Icon": self.extractURLString(heroBuildPage, response: response, range: result!.rangeAtIndex(11))!,
                "talentLevel16Name": self.extractString(heroBuildPage, response: response, range: result!.rangeAtIndex(12)),
                "talentLevel16Icon": self.extractURLString(heroBuildPage, response: response, range: result!.rangeAtIndex(13))!,
                "talentLevel20Name": self.extractString(heroBuildPage, response: response, range: result!.rangeAtIndex(14)),
                "talentLevel20Icon": self.extractURLString(heroBuildPage, response: response, range: result!.rangeAtIndex(15))!
            ]);
        }

        if heroBuilds.isEmpty {
            completionHandler(heroBuild: nil, error: NSError(domain: "Unable to extract list of talents from \(response.URL!), the site may be temporarily unavailable", code: 0, userInfo: nil))
        } else {
            // Sort builds by popularity.
            heroBuilds.sortInPlace {
                $0["gamesPlayed"] as! Int > $1["gamesPlayed"] as! Int
            }

            // Call completion handler with most popular build.
            let heroBuild: [[String: AnyObject]] = [
                ["level":  1, "name": heroBuilds.first!["talentLevel1Name"]!,  "iconURL": heroBuilds.first!["talentLevel1Icon"]!],
                ["level":  4, "name": heroBuilds.first!["talentLevel4Name"]!,  "iconURL": heroBuilds.first!["talentLevel4Icon"]!],
                ["level":  7, "name": heroBuilds.first!["talentLevel7Name"]!,  "iconURL": heroBuilds.first!["talentLevel7Icon"]!],
                ["level": 10, "name": heroBuilds.first!["talentLevel10Name"]!, "iconURL": heroBuilds.first!["talentLevel10Icon"]!],
                ["level": 13, "name": heroBuilds.first!["talentLevel13Name"]!, "iconURL": heroBuilds.first!["talentLevel13Icon"]!],
                ["level": 16, "name": heroBuilds.first!["talentLevel16Name"]!, "iconURL": heroBuilds.first!["talentLevel16Icon"]!],
                ["level": 20, "name": heroBuilds.first!["talentLevel20Name"]!, "iconURL": heroBuilds.first!["talentLevel20Icon"]!]
            ]

            completionHandler(heroBuild: heroBuild, error: nil)
        }
    }

    // MARK: - Image Assets

    func taskForImageWithURL(URL: NSURL, completionHandler: (data: NSData?, error: NSError?) -> Void) -> NSURLSessionDataTask {
        return NSURLSession.sharedSession().dataTaskWithURL(URL) { data, response, error in
            if error != nil {
                completionHandler(data: nil, error: error)
            } else {
                completionHandler(data: data, error: nil)
            }
        }
    }

    // MARK: - Helpers

    private func extractString(page: String, response: NSURLResponse, range: NSRange) -> String {
        return (page as NSString).substringWithRange(range)
    }

    private func extractURLString(page: String, response: NSURLResponse, range: NSRange) -> String? {
        return NSURL(string: extractString(page, response: response, range: range), relativeToURL: response.URL)?.absoluteString
    }

    private func extractInteger(page: String, response: NSURLResponse, range: NSRange) -> Int? {
        return Int(extractString(page, response: response, range: range))
    }
}