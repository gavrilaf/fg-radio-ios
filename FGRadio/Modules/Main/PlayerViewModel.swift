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
import MediaPlayer

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
                
                print("model status: \(status)")
                
                switch status {
                case .starting, .preparingToPlay:
                    self.isButtonEnabled = false
                    self.showError = false
                    self.buttonState = ButtonState.play.rawValue
                    self.indicatorState = .pause
                case .error:
                    self.isButtonEnabled = true
                    self.showError = true
                    self.buttonState = ButtonState.play.rawValue
                    self.indicatorState = .pause
                case .readyToPlay:
                    self.isButtonEnabled = true
                    self.showError = false
                    self.buttonState = ButtonState.play.rawValue
                    self.indicatorState = .pause
                case .playing:
                    self.isButtonEnabled = true
                    self.showError = false
                    self.buttonState = ButtonState.pause.rawValue
                    self.indicatorState = .play
                }
            }
            
            player.$trackTitle.sink { [weak self] in
                self?.trackTitle = $0
            }
            
            player.$volume.sink { [weak self] in
                self?.volume = $0
            }
        }
        
        self.volume = player.volume
    }
        
    func playTapped() {
        if player.status == .playing {
            player.pause()
        } else {
            player.play()
        }
    }
    
    func openLink(type: LinkType) {
        let url: URL
        switch type {
        case .instagram:
            url = Config.config.intstagramUrl
        case .fb:
            if UIApplication.shared.canOpenURL(Config.config.fbAppUrl) {
                url = Config.config.fbAppUrl
            } else {
                url = Config.config.fbUrl
            }
        case .youTube:
            url = Config.config.youtubeUrl
        case .site:
            url = Config.config.siteUrl
        }
        
        UIApplication.shared.open(url)
    }
    
    func updateVolume() {
        player.volume = volume
    }
    
    @Published var volume: Float = 0.5
    
    @Published var indicatorState: MusicIndicator.AudioState = .pause
    @Published private(set) var trackTitle = TrackTitle.makeEmpty()
    @Published private(set) var isButtonEnabled = false
    @Published private(set) var buttonState = ButtonState.play.rawValue
    @Published private(set) var showError = false
    
    // MARK:- private
    
    private let player: Player
    private var cancelBag = CancelBag()
}
