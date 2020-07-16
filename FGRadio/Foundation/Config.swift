//
//  Config.swift
//  FGRadio
//
//  Created by Eugen Fedchenko on 19.06.2020.
//  Copyright © 2020 Eugen Fedchenko. All rights reserved.
//
import Foundation
import FirebaseRemoteConfig

// MARK:- RemoteConfigWrapper
@propertyWrapper
struct RemoteConfigStringWrapper {
    let key: String
    let defaultValue: String

    init(_ key: String, defaultValue: String) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: String {
        get {
            let value = Config.config.remote.configValue(forKey: key)
            return value.stringValue ?? defaultValue
        }
    }
}

@propertyWrapper
struct RemoteConfigURLWrapper {
    let key: String
    let defaultValue: URL

    init(_ key: String, defaultValue: String) {
        self.key = key
        self.defaultValue = URL(string: defaultValue)!
    }

    var wrappedValue: URL {
        get {
            let value = Config.config.remote.configValue(forKey: key)
            guard let s = value.stringValue, let url = URL(string: s) else {
                return defaultValue
            }
            return url
        }
    }
}


// MARK:- Config
final class Config {
    
    static let config = Config()
    
    @RemoteConfigURLWrapper("stream_url", defaultValue: "http://217.25.202.21:8000/live")
    var streamUrl: URL
    
    @RemoteConfigURLWrapper("intstagram_url", defaultValue: "https://www.instagram.com/firstgearshow/")
    var intstagramUrl: URL
    
    @RemoteConfigURLWrapper("fb_url", defaultValue: "https://www.facebook.com/FirstGearShow/")
    var fbUrl: URL
    
    @RemoteConfigURLWrapper("youtube_url", defaultValue: "https://www.youtube.com/channel/UCMJ2LV3LxETcHcW6uKRDPHQ")
    var youtubeUrl: URL
    
    @RemoteConfigURLWrapper("site_url", defaultValue: "https://firstgear.ua/")
    var siteUrl: URL
    
    init() {}
    
    func fetch() {
        remote.fetch() { [weak self] (status, error) -> Void in
            guard let self = self else { return }
            if status == .success {
                self.remote.activate() { (changed, error) in
                    if error != nil {
                        print("Config activating error: \(error?.localizedDescription ?? "No error available.")")
                    } else {
                        print("Config activated!")
                    }
                }
            } else {
                print("Config fetching error: \(error?.localizedDescription ?? "No error available.")")
            }
        }
    }
    
    fileprivate lazy var remote: RemoteConfig = {
        let config = RemoteConfig.remoteConfig()
        
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        
        config.configSettings = settings
        
        return config
    }()
}


