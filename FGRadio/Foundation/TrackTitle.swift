//
//  TrackTitle.swift
//  FGRadio
//
//  Created by Eugen Fedchenko on 05.07.2020.
//  Copyright © 2020 Eugen Fedchenko. All rights reserved.
//

import Foundation
import SwiftUI

struct TrackTitle {
    private enum Const {
        static let empty = "#empty#"
    }
    
    init(title: String, subtitle: String = Const.empty) {
        self.title = TrackTitle.trim(title)
        self.subtitle = TrackTitle.trim(subtitle)
    }
    
    var isTitleEmpty: Bool { title == Const.empty }
    var isSubtitleEmpty: Bool { subtitle == Const.empty }
    
    let title: String
    let subtitle: String
    
    var titleColor: Color {
        if title != Const.empty {
            return Color.primaryText
        }
        return Color.mainBackground
    }
    
    var sublitleColor: Color {
        if subtitle != Const.empty {
            return Color.secondaryText
        }
        return Color.mainBackground
    }
    
    static private func trim(_ s: String) -> String {
        let ss = s.trimmingCharacters(in: .whitespaces)
        return ss.isEmpty ? Const.empty : ss
    }
}

extension TrackTitle {
    static func makeEmpty() -> TrackTitle {
        return TrackTitle(title: TrackTitle.Const.empty, subtitle: TrackTitle.Const.empty)
    }
        
    static func makeFrom(streamTitle: String) -> TrackTitle {
        let components = streamTitle.components(separatedBy: "-")
        if components.count >= 2 {
            return TrackTitle(title: components[0], subtitle: components[1...].joined(separator: " "))
        } else {
            return TrackTitle(title: streamTitle)
        }
    }
}


