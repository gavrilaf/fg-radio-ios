//
//  Banner.swift
//  FGRadio
//
//  Created by Eugen Fedchenko on 20.10.2020.
//  Copyright © 2020 Eugen Fedchenko. All rights reserved.
//

import SwiftUI

struct BannerModifier: ViewModifier {
    var title: String
    var show: Bool
    
    var height: CGFloat {
        UIApplication.shared.statusBarFrame.height + 25
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
            if self.show {
                VStack(spacing: 0) {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(title)
                            Spacer()
                        }.padding()
                    }
                    .edgesIgnoringSafeArea(.all)
                    .frame(height: height)
                    .background(Color.banner)
                    .opacity(0.7)
                    
                    Spacer()
                }
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

extension View {
    func banner(title: String, show: Bool) -> some View {
        self.modifier(BannerModifier(title: title, show: show))
    }
}

struct Banner_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello word")
            .banner(title: "No internet", show: true)
    }
}
