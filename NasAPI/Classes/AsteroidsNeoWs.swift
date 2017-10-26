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
    public let id: Int
    public let name: String
    public let jplUrl: String
    public let diameter: Double
    public let hazardous: Bool
    public let closeApproach: [CloseApproachData]
    
    init?(fromJSON: JSON) {
        //TODO: Implement
        return nil
    }
}

public struct CloseApproachData {
    public let date: Date
    public let relativeSpeed: Double
    public let distance: Double
    public let orbitingBody: String
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
                dateFormatter.dateFormat = "YYYY-MM-DD"
                let dateString = dateFormatter.string(from: date)
                if let objects = json["near_earth_objects"][dateString].array {
                    getAsteroids(fromJSON: objects, completion: completion)
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
