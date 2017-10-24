//
//  RoverImages.swift
//  NasAPI-Swift
//
//  Created by Jari Koopman on 23/10/2017.
//
import Alamofire
import AlamofireImage
import SwiftyJSON

public typealias RoverImageCompletion = ([RoverImage]?, Error?) -> Void
public typealias RoverImageReturnValue = (images: [RoverImage], continue: Bool)

public enum RoverError: String, Error {
    case InvalidRover = "Invalid Rover Name"
    case InvalidAPIKey
    case FailedToInitializeObject
    case Unknown
}

public class RoverImage {
    public let id: Int
    public let sol: Int
    public let camera: RoverCamera
    public let imgSrc: URLConvertible
    public let earthDate: Date
    public let roverName: String
    
    init?(withJSON json: JSON) {
        guard let id = json["id"].int else {return nil}
        guard let sol = json["sol"].int else {return nil}
        guard let cameraName = json["camera"]["name"].string else {return nil}
        guard let camera = RoverCamera(rawValue: cameraName) else {return nil}
        guard let imgSrc = json["img_src"].string else {return nil}
        guard let earthDateString = json["earth_date"].string else {return nil}
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-DD"
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

public enum RoverCamera: String {
    case fhaz = "FHAZ"
    case rhaz = "RHAZ"
    case mast = "MAST"
    case chemcam = "CHEMCAM"
    case mahli = "MAHLI"
    case mardi = "MARDI"
    case navcam = "NAVCAM"
}


extension NasAPI {
    public class func getImages(forRoverWithName roverName: String, andSol sol: Int, page: Int=0, completion: @escaping RoverImageCompletion, images: [RoverImage]=[]) {
        var url = "https://api.nasa.gov/mars-photos/api/v1/rovers/\(roverName)/photos?sol=\(sol)"
        url += "&page=\(page)"
        if NasAPI.APIKey != "" {
            url += "&api_key=\(NasAPI.APIKey)"
        } else {
            completion(nil, RoverError.InvalidAPIKey)
        }
        Alamofire.request(url).responseJSON { (response) in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                if let error = json["errors"].string {
                    completion(nil, RoverError(rawValue: error) ?? RoverError.Unknown)
                }
                let images = NasAPI.getImages(fromJSON: json, atPage: page, withSol: sol, forRover: roverName, andWithImages: images, completion: completion)
                if !images.continue {
                    completion(images.images, nil)
                    return
                }
            case .failure(let error):
                completion(nil, error)
                return
            }
        }
    }
    
    fileprivate class func getImages(fromJSON json: JSON, atPage page: Int, withSol sol: Int, forRover rover: String, andWithImages images: [RoverImage], completion: @ escaping RoverImageCompletion) -> RoverImageReturnValue {
        guard let photosArray = json["photos"].array else {return (images, false)}
        var images = images
        guard photosArray != [] else {return (images, false)}
        for imageJSON in photosArray {
            if let image = RoverImage(withJSON: imageJSON) {
                images.append(image)
            } else {
                completion(nil, RoverError.FailedToInitializeObject)
            }
        }
        let page = page + 1
        NasAPI.getImages(forRoverWithName: rover, andSol: sol, page: page, completion: completion, images: images)
        return (images, true)
    }
}
