//
//  PlayerViewModel.swift
//  FGRadio
//
//  Created by Eugen Fedchenko on 20.06.2020.
//  Copyright © 2020 Eugen Fedchenko. All rights reserved.
//

import Foundation
import Combine
import UIKit

final class PlayerViewModel: ObservableObject {
    
    enum LinkType {
        case instagram
        case fb
        case youTube
        case site
    }
    
    enum ButtonState: String {
        case play = "play-dark"
        case pause = "pause-dark"
    }
    
    init(player: Player) {
        self.player = player
        
        cancelBag.collect {
            player.$status.sink { [weak self] (status) in
                guard let self = self else { return }
                
                switch status {
                case .starting, .preparingToPlay, .error:
                    self.isButtonEnabled = false
                    self.buttonState = ButtonState.play.rawValue
                    self.indicatorState = .pause
                    self.trackTitle = TrackTitle.makeEmpty()
                case .readyToPlay:
                    self.isButtonEnabled = true
                    self.buttonState = ButtonState.play.rawValue
                    self.indicatorState = .pause
                case .playing:
                    self.isButtonEnabled = true
                    self.buttonState = ButtonState.pause.rawValue
                    self.indicatorState = .play
                }
            }
            
            player.$trackTitle.sink { [weak self] (title) in
                guard let self = self else { return }
                self.trackTitle = title
            }
        }
    }
    
    func playTapped() {
        if player.status == .readyToPlay {
            player.play()
        } else if player.status == .playing {
            player.pause()
        }
    }
    
    func openLink(type: LinkType) {
        let url: URL
        switch type {
        case .instagram:
            url = Config.config.intstagramUrl
        case .fb:
            url = Config.config.fbUrl
        case .youTube:
            url = Config.config.youtubeUrl
        case .site:
            url = Config.config.siteUrl
        }
        
        UIApplication.shared.open(url)
    }
    
    @Published private(set) var trackTitle = TrackTitle.makeEmpty()
    @Published private(set) var isButtonEnabled = false
    @Published private(set) var buttonState = ButtonState.play.rawValue
    
    @Published var indicatorState: MusicIndicator.AudioState = .pause
    
    private let player: Player
    private var cancelBag = CancelBag()
}
