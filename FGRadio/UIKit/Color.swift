//
//  Color.swift
//  FGRadio
//
//  Created by Eugen Fedchenko on 05.07.2020.
//  Copyright © 2020 Eugen Fedchenko. All rights reserved.
//

import SwiftUI

extension Color {
    static let mainBackground = Color(UIColor.black)
    static let primaryText = Color(UIColor.white)
    static let secondaryText = Color(UIColor.gray)
    static let errorText = Color.red
    
    static let banner = Color(UIColor(hex: "#fd9426ff")!)
}

extension UIColor {
    public convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }

        return nil
    }
}
