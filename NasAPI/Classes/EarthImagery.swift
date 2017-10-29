//
//  EarthImagery.swift
//  NasAPI
//
//  Created by Jari Koopman on 27/10/2017.
//

import Alamofire
import AlamofireImage
import SwiftyJSON
import CoreLocation

public typealias DownloadEarthImageCompletion = (Image?, EarthImageError?) -> Void
public typealias EarthImageCompletion = (EarthImage?, EarthImageError?) -> Void
public typealias EarthAssetCompletion = ([EarthAsset]?, EarthImageError?) -> Void

public enum EarthImageError: String, Error {
    case IndexOutOfRange = "list index out of range"
    case NoResultsReturned
    case FailedToInitializeImage
    case FailedToInitalizeAsset
    case FailedToGetImage
    case InvalidAPIKey
    case Unknown
}

/// Holds an earth asset object
public struct EarthAsset {
    /// Asset ID
    public let id: String
    /// Date the asset was created
    public let date: Date
    
    /// Date the asset was created
    public var dateStr: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: self.date)
    }
    
    /// Initializes EarthAsset object fom a JSON
    init?(fromJSON json: JSON) {
        guard let dateStr = json["date"].string else {return nil}
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'hh-mm-ss"
        guard let date = dateFormatter.date(from: dateStr) else {return nil}
        guard let id = json["id"].string else {return nil}
        
        self.id = id
        self.date = date
    }
}

/// Holds an earth image object
public class EarthImage {
    /// Date Image was created
    public let date: Date
    /// URL to image file
    public let url: String
    /// Image ID
    public let id: String
    /// Percentage of clouds on image
    public let cloudScore: Double?
    
    public var dateStr: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: self.date)
    }
    
    /// Initializes EarthImage object fom a JSON
    init?(fromJSON json: JSON) {
        guard let dateStr = json["date"].string else {return nil}
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'hh-mm-ss"
        guard let date = dateFormatter.date(from: dateStr) else {return nil}
        guard let url = json["url"].string else {return nil}
        guard let id = json["id"].string else {return nil}
        if let cloudScore = json["cloud_score"].double {
            self.cloudScore = cloudScore
        } else {
            self.cloudScore = nil
        }
        
        self.date = date
        self.url = url
        self.id = id
    }
    
    /// Gets the image file for the EarthImage object
    public func getImage(completion: @escaping DownloadEarthImageCompletion) {
        Alamofire.request(url).responseImage { (response) in
            if response.error != nil {
                completion(nil, .FailedToGetImage)
            }
            if let image = response.result.value {
                completion(image, nil)
            }
        }
    }
}

extension NasAPI {
    public class func getImage(forLocation location: CLLocation, withCloudScore cloudScore: Bool = false, completion: @escaping EarthImageCompletion) {
        NasAPI.getEarthImageAssets(forLocation: location) { (assets, error) in
            if let error = error {
                completion(nil, error); return
            }
            guard var assets = assets else {completion(nil, .NoResultsReturned); return}
            assets = assets.sorted { $0.date > $1.date }
            guard let closestAsset = assets.first else {completion(nil, .NoResultsReturned); return}
            NasAPI.getImage(forAsset: closestAsset, andLocation: location, withCloudScore: cloudScore, completion: completion)
        }
    }
    
    class func getImage(forAsset asset: EarthAsset, andLocation location: CLLocation, withCloudScore cloudScore: Bool, completion: @escaping EarthImageCompletion) {
        var url = "https://api.nasa.gov/planetary/earth/imagery"
        url += "?lon=\(location.coordinate.longitude)"
        url += "&lat=\(location.coordinate.latitude)"
        url += "&date=\(asset.dateStr)"
        if cloudScore { url += "&cloud_score=true" }
        if NasAPI.APIKey != "" {
            url += "&api_key=\(NasAPI.APIKey)"
        } else {
            completion(nil, .InvalidAPIKey)
        }
        
        Alamofire.request(url).responseJSON { (response) in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if let earthImage = EarthImage(fromJSON: json) {
                    completion(earthImage, nil)
                } else {
                    completion(nil, .FailedToInitializeImage)
                }
            case .failure( _):
                completion(nil, .NoResultsReturned)
            }
        }
    }
    
    public class func getEarthImageAssets(forLocation location: CLLocation, completion: @escaping EarthAssetCompletion) {
        var url = "https://api.nasa.gov/planetary/earth/assets"
        url += "?lon=\(location.coordinate.longitude)"
        url += "&lat=\(location.coordinate.latitude)"
        if NasAPI.APIKey != "" {
            url += "&api_key=\(NasAPI.APIKey)"
        } else {
            completion(nil, .InvalidAPIKey)
        }
        Alamofire.request(url).responseJSON { (response) in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if let error = json["error"].string {
                    completion(nil, EarthImageError(rawValue: error) ?? .Unknown)
                    return
                }
                guard let results = json["results"].array, results.count > 0 else {completion(nil, EarthImageError.NoResultsReturned); return}
                var assets: [EarthAsset] = []
                for result in results {
                    if let asset = EarthAsset(fromJSON: result) {
                        assets.append(asset)
                    } else {
                        completion(nil, .FailedToInitalizeAsset)
                        return
                    }
                }
                completion(assets, nil)
                return
            case .failure( _):
                completion(nil, .NoResultsReturned)
                return
            }
        }
    }
}









