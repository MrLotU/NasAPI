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

public class Asteroid {
    public let id: String
    public let name: String
    public let jplUrl: String
    public let diameter: Double
    public let hazardous: Bool
    public let approachData: CloseApproachData
    
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

public struct CloseApproachData {
    public let date: Date
    public let relativeSpeed: String
    public let distance: String
    public let orbitingBody: String
    
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
