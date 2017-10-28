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

public typealias DownloadEarthImageCompletion = (Image?, Error?) -> Void
public typealias EarthImageCompletion = (EarthImage?, Error?) -> Void
public typealias EarthAssetCompletion = ([EarthAsset]?, Error?) -> Void

public enum EarthImageError: String, Error {
    case IndexOutOfRange = "list index out of range"
    case NoResultsReturned
    case FailedToInitializeImage
    case FailedToInitalizeAsset
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
        dateFormatter.dateFormat = "yyyy-MM-dd"
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
    
    /// Initializes EarthImage object fom a JSON
    init?(fromJSON json: JSON) {
        guard let dateStr = json["date"].string else {return nil}
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: dateStr) else {return nil}
        guard let url = json["url"].string else {return nil}
        guard let id = json["id"].string else {return nil}
        
        self.date = date
        self.url = url
        self.id = id
    }
    
    /// Gets the image file for the EarthImage object
    public func getImage(completion: @escaping DownloadEarthImageCompletion) {
        Alamofire.request(url).responseImage { (response) in
            if let error = response.error {
                completion(nil, error)
            }
            if let image = response.result.value {
                completion(image, nil)
            }
        }
    }
}

extension NasAPI {
    public class func getImage(forLocation location: CLLocation, completion: @escaping EarthImageCompletion) {
        NasAPI.getEarthImageAssets(forLocation: location) { (assets, error) in
            if let error = error {
                completion(nil, error); return
            }
            guard var assets = assets else {completion(nil, EarthImageError.NoResultsReturned); return}
            assets = assets.sorted { $0.date > $1.date }
            guard let closestAsset = assets.first else {completion(nil, EarthImageError.NoResultsReturned); return}
            NasAPI.getImage(forAsset: closestAsset, andLocation: location, completion: completion)
        }
    }
    
    class func getImage(forAsset asset: EarthAsset, andLocation location: CLLocation, completion: @escaping EarthImageCompletion) {
        var url = "https://api.nasa.gov/planetary/earth/imagery"
        url += "?lon=\(location.coordinate.longitude)"
        url += "&lat=\(location.coordinate.latitude)"
        url += "&date=\(asset.dateStr)"
        url += "&api_key=\(NasAPI.APIKey)"
        
        Alamofire.request(url).responseJSON { (response) in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if let earthImage = EarthImage(fromJSON: json) {
                    completion(earthImage, nil)
                } else {
                    completion(nil, EarthImageError.FailedToInitializeImage)
                }
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    public class func getEarthImageAssets(forLocation location: CLLocation, completion: @escaping EarthAssetCompletion) {
        var url = "https://api.nasa.gov/planetary/earth/assets"
        url += "?lon=\(location.coordinate.longitude)"
        url += "&lat=\(location.coordinate.latitude)"
        url += "&api_key=\(NasAPI.APIKey)"
        Alamofire.request(url).responseJSON { (response) in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if let error = json["error"].string {
                    completion(nil, EarthImageError(rawValue: error) ?? EarthImageError.Unknown)
                    return
                }
                guard let results = json["results"].array, results.count > 0 else {completion(nil, EarthImageError.NoResultsReturned); return}
                var assets: [EarthAsset] = []
                for result in results {
                    if let asset = EarthAsset(fromJSON: result) {
                        assets.append(asset)
                    } else {
                        completion(nil, EarthImageError.FailedToInitalizeAsset)
                        return
                    }
                }
                completion(assets, nil)
                return
            case .failure(let error):
                completion(nil, error)
                return
            }
        }
    }
}









