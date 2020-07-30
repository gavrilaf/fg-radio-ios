//
//  VolumeView.swift
//  FGRadio
//
//  Created by Eugen Fedchenko on 22.07.2020.
//  Copyright © 2020 Eugen Fedchenko. All rights reserved.
//

import MediaPlayer
import UIKit

extension MPVolumeView {
    func setVolume(_ volume: Float) {
        // Hacky solution but I don't know better
        guard let slider = self.subviews.first(where: { $0 is UISlider }) as? UISlider else { return }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider.value = volume
        }
    }
}
