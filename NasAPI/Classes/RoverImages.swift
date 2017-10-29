//
//  RoverImages.swift
//  NasAPI-Swift
//
//  Created by Jari Koopman on 23/10/2017.
//
import Alamofire
import AlamofireImage
import SwiftyJSON

public typealias RoverImageCompletion = ([RoverImage]?, RoverError?) -> Void
public typealias RoverImageReturnValue = (images: [RoverImage], continue: Bool)
public typealias RoverImageDownloadCompletion = (Image?, RoverError?) -> Void

//MARK: Enums

public enum RoverError: String, Error {
    case InvalidRover = "Invalid Rover Name"
    case InvalidAPIKey
    case FailedToInitializeRoverImage
    case FailedToGetImage
    case NoResultsReturned
    case Unknown
}

/// All available rover cameras
public enum RoverCamera: String {
    case fhaz = "FHAZ"
    case rhaz = "RHAZ"
    case mast = "MAST"
    case chemcam = "CHEMCAM"
    case mahli = "MAHLI"
    case mardi = "MARDI"
    case navcam = "NAVCAM"
}

//MARK: Classes

/// Holds a RoverImage object
public class RoverImage {
    /// Image ID
    public let id: Int
    /// Image SOL (martian date)
    public let sol: Int
    /// Camera that took the image
    public let camera: RoverCamera
    /// Imagae source URL
    public let imgSrc: String
    /// Earth date the image was taken
    public let earthDate: Date
    /// Rover that took the image
    public let roverName: String
    
    /// Gets the Image object for the RoverImage object
    public func getImage(completion: @escaping RoverImageDownloadCompletion) {
        Alamofire.request(imgSrc).responseImage { (response) in
            if response.error != nil {
                completion(nil, .FailedToGetImage)
            }
            if let image = response.result.value {
                completion(image, nil)
            }
        }
    }
    
    //MARK: Initalizers
    /// Initializes RoverImage object from a JSON
    init?(withJSON json: JSON) {
        guard let id = json["id"].int else {return nil}
        guard let sol = json["sol"].int else {return nil}
        guard let cameraName = json["camera"]["name"].string else {return nil}
        guard let camera = RoverCamera(rawValue: cameraName) else {return nil}
        guard let imgSrc = json["img_src"].string else {return nil}
        guard let earthDateString = json["earth_date"].string else {return nil}
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        guard let date = dateFormatter.date(from: earthDateString) else {return nil}
        guard let roverName = json["rover"]["name"].string else {return nil}
        
        self.id = id
        self.sol = sol
        self.camera = camera
        self.imgSrc = imgSrc
        self.earthDate = date
        self.roverName = roverName
    }
}

extension NasAPI {
    /// Gets all images by a specific rover for a specific sol (martian date)
    public class func getImages(forRoverWithName roverName: String, andSol sol: Int, page: Int=0, completion: @escaping RoverImageCompletion) {
        var url = "https://api.nasa.gov/mars-photos/api/v1/rovers/\(roverName)/photos?sol=\(sol)"
        url += "&page=\(page)"
        if NasAPI.APIKey != "" {
            url += "&api_key=\(NasAPI.APIKey)"
        } else {
            completion(nil, .InvalidAPIKey)
        }
        Alamofire.request(url).responseJSON { (response) in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if let error = json["errors"].string {
                    completion(nil, RoverError(rawValue: error) ?? .Unknown)
                }
                let images = NasAPI.getImages(fromJSON: json, atPage: page, withSol: sol, forRover: roverName, completion: completion)
                completion(images.images, nil)
                return
            case .failure( _):
                completion(nil, .NoResultsReturned)
                return
            }
        }
    }
    
    fileprivate class func getImages(fromJSON json: JSON, atPage page: Int, withSol sol: Int, forRover rover: String, completion: @escaping RoverImageCompletion) -> RoverImageReturnValue {
        var images: [RoverImage] = []
        guard let photosArray = json["photos"].array else {return (images, false)}
        guard photosArray != [] else {return (images, false)}
        for imageJSON in photosArray {
            if let image = RoverImage(withJSON: imageJSON) {
                images.append(image)
            } else {
                completion(nil, .FailedToInitializeRoverImage)
            }
        }
        let page = page + 1
        NasAPI.getImages(forRoverWithName: rover, andSol: sol, page: page, completion: completion)
        return (images, true)
    }
}
