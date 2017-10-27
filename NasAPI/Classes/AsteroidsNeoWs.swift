//
//  AsteroidsNeoWs.swift
//  NasAPI
//
//  Created by Jari Koopman on 25/10/2017.
//

import Alamofire
import SwiftyJSON

public typealias AsteroidCopmletion = ([Asteroid]?, Error?) -> Void

public enum NeoWsError: Error {
    case FailedToInitializeObject
    case Unknown
}

/// Holds an asteroid object
public class Asteroid {
    /// Asteroid ID
    public let id: String
    /// Asteroid Name
    public let name: String
    /// JPL URL, holds more info
    public let jplUrl: String
    /// Asteroid diameter in meters
    public let diameter: Double
    /// Bool indicating if asteroid is potentially hazardous to earth
    public let hazardous: Bool
    /// Approach Data
    public let approachData: CloseApproachData
    
    //MARK: Initializers
    /// Initializes Asteroid object fom a JSON
    init?(fromJSON json: JSON) {
        guard let id = json["neo_reference_id"].string else {return nil}
        guard let name = json["name"].string else {return nil}
        guard let jplUrl = json["nasa_jpl_url"].string else {return nil}
        guard let diameterMin = json["estimated_diameter"]["meters"]["estimated_diameter_min"].double else {return nil}
        guard let diameterMax = json["estimated_diameter"]["meters"]["estimated_diameter_max"].double else {return nil}
        let diameter = (diameterMax/diameterMin) * 2.0
        guard let hazardous = json["is_potentially_hazardous_asteroid"].bool else {return nil}
        guard let approachJSON = json["close_approach_data"].array else {return nil}
        guard let approachData = CloseApproachData(fromJSON: approachJSON[0]) else {return nil}
        
        self.id = id
        self.name = name
        self.jplUrl = jplUrl
        self.diameter = diameter
        self.hazardous = hazardous
        self.approachData = approachData
    }
}

/// Holding all close approach data for an asteroid
public struct CloseApproachData {
    /// Date the data was measured
    public let date: Date
    /// Relative speed of the asteroid (relative to orbiting body) in kilometers per hour
    public let relativeSpeed: String
    /// Distance to orbiting body in kilometers
    public let distance: String
    /// Body the asteroid is orbiting
    public let orbitingBody: String
    
    //MARK: Initializers
    /// Initializes CloseApproachData object from a JSON
    init?(fromJSON json: JSON) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        guard let dateStr = json["close_approach_date"].string else {return nil}
        guard let date = dateFormatter.date(from: dateStr) else {return nil}
        guard let speed = json["relative_velocity"]["kilometers_per_hour"].string else {return nil}
        guard let distance = json["miss_distance"]["kilometers"].string else {return nil}
        guard let orbitingBody = json["orbiting_body"].string else {return nil}
        
        self.date = date
        self.relativeSpeed = speed
        self.distance = distance
        self.orbitingBody = orbitingBody
    }
}

extension NasAPI {
    /// Gets all asteroids for the date of today
    public class func getAsteroidDataForToday(detailed: Bool = false, completion: @escaping AsteroidCopmletion) {
        var url = "https://api.nasa.gov/neo/rest/v1/feed/today"
        if detailed {
            url += "?detailed=true"
        } else {
            url += "?detailed=false"
        }
        url += "&api_key=\(NasAPI.APIKey)"
        Alamofire.request(url).responseJSON { (response) in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                let date = Date()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "YYYY-MM-dd"
                let dateString = dateFormatter.string(from: date)
                if let objects = json["near_earth_objects"][dateString].array {
                    getAsteroids(fromJSON: objects, completion: completion)
                } else {
                    print(dateString)
                    completion(nil, NeoWsError.Unknown)
                }
            case .failure(let error):
                completion(nil, error)
            }
        }
    }

    /// Creates Asteroids from JSON objects
    fileprivate class func getAsteroids(fromJSON jsonArray: [JSON], completion: @escaping AsteroidCopmletion) {
        var asteroids: [Asteroid] = []
        for json in jsonArray {
            if let asteroid = Asteroid(fromJSON: json) {
                asteroids.append(asteroid)
            } else {
                completion(nil, NeoWsError.FailedToInitializeObject)
            }
        }
        completion(asteroids, nil)
    }
}
