//
//  TrackTitle.swift
//  FGRadio
//
//  Created by Eugen Fedchenko on 05.07.2020.
//  Copyright © 2020 Eugen Fedchenko. All rights reserved.
//

import Foundation

struct TrackTitle {
    let title: String
    let subtitle: String
}

extension TrackTitle {
    static func makeEmpty() -> TrackTitle {
        return TrackTitle(title: "", subtitle: "")
    }
        
    static func makeFrom(streamTitle: String) -> TrackTitle {
        let components = streamTitle.components(separatedBy: "-")
        if components.count >= 2 {
            return TrackTitle(title: components[0], subtitle: components[1...].joined(separator: " "))
        } else {
            return TrackTitle(title: streamTitle, subtitle: "")
        }
    }
}
