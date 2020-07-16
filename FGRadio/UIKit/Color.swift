//
//  Color.swift
//  FGRadio
//
//  Created by Eugen Fedchenko on 05.07.2020.
//  Copyright © 2020 Eugen Fedchenko. All rights reserved.
//

import SwiftUI

extension Color {
    public init(hex: String) {
        guard hex.hasPrefix("#") && hex.count == 7 else {
            fatalError("Invalid color string \(hex)")
        }
        
        let scanner = Scanner(string: String(hex[hex.index(after: hex.startIndex)...]))
        var hexNumber: UInt64 = 0
        guard scanner.scanHexInt64(&hexNumber) else {
           fatalError("Invalid color string \(hex)")
        }
        
        let r = Double((hexNumber & 0xff0000) >> 16) / 255
        let g = Double((hexNumber & 0x00ff00) >> 8) / 255
        let b = Double((hexNumber & 0x0000ff)) / 255
        
        self.init(red: r, green: g, blue: b)
    }
    
    static let backgroundDark = Color("#202020")
    
    static let secondaryTextDark = Color(UIColor(red: 0.529, green: 0.529, blue: 0.529, alpha: 1))
}

