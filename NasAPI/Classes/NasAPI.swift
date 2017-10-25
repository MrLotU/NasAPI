//
//  NasAPI.swift
//  NasAPI-Swift
//
//  Created by Jari Koopman on 23/10/2017.
//
import UIKit

public class NasAPI {
    static var APIKey = ""
    
    public class func setApiKey(_ key: String) {
        NasAPI.APIKey = key
    }
}
