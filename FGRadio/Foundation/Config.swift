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
            let value = Config.shared.remote.configValue(forKey: key)
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
            let value = Config.shared.remote.configValue(forKey: key)
            guard let s = value.stringValue, let url = URL(string: s) else {
                return defaultValue
            }
            return url
        }
    }
}


// MARK:- Config
final class Config {
    
    static let shared = Config()
    
    @RemoteConfigStringWrapper("config_version", defaultValue: "1.0.local")
    var version: String
    
    @RemoteConfigURLWrapper("stream_url", defaultValue: "http://c2.radioboss.fm:8252/stream")
    var streamUrl: URL 
    
    @RemoteConfigURLWrapper("intstagram_url", defaultValue: "https://www.instagram.com/firstgearshow/")
    var intstagramUrl: URL
    
    @RemoteConfigURLWrapper("fb_url", defaultValue: "https://www.facebook.com/FirstGearShow/")
    var fbUrl: URL
    
    @RemoteConfigURLWrapper("fb_app_url", defaultValue: "fb://profile/148818115286637/")
    var fbAppUrl: URL
    
    @RemoteConfigURLWrapper("youtube_url", defaultValue: "https://www.youtube.com/channel/UCMJ2LV3LxETcHcW6uKRDPHQ")
    var youtubeUrl: URL
    
    @RemoteConfigURLWrapper("site_url", defaultValue: "https://firstgear.ua/")
    var siteUrl: URL
    
    @RemoteConfigURLWrapper("studio_phone_number", defaultValue: "tel://0671285588")
    var studioPhone: URL
    
    @RemoteConfigURLWrapper("tg_link", defaultValue: "https://t.me/fg_radio")
    var tgLink: URL
    
    init() {}
    
    func fetch(completion: @escaping () -> Void) {
        remote.fetchAndActivate { (status, error) in
            if let error = error {
                print("Config fetching error: \(error.localizedDescription)")
            } else {
                print("Remote config fetched")
            }
            
            completion()
        }
    }
    
    fileprivate lazy var remote: RemoteConfig = {
        let config = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        
        config.configSettings = settings
        return config
    }()
}


