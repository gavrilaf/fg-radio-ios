//
//  VolumeSlider.swift
//  FGRadio
//
//  Created by Eugen Fedchenko on 22.07.2020.
//  Copyright © 2020 Eugen Fedchenko. All rights reserved.
//

import MediaPlayer
import UIKit
import SwiftUI

struct VolumeSlider: UIViewRepresentable {
   func makeUIView(context: Context) -> MPVolumeView {
      MPVolumeView(frame: .zero)
   }

   func updateUIView(_ view: MPVolumeView, context: Context) {}
}
