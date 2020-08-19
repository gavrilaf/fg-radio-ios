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
        case preparing
        case play
        case pause
    }
    
    init(player: Player) {
        self.player = player

        cancelBag.collect {
            player.$status.sink { [weak self] (status) in
                guard let self = self else { return }
                
                print("model status: \(status)")
                
                switch status {
                case .starting:
                    self.isButtonEnabled = false
                    self.showError = false
                    self.buttonState = ButtonState.preparing
                    self.indicatorState = .pause
                
                case .preparingToPlay:
                    if self.alreadyPlayed {
                        self.isButtonEnabled = false
                        self.showError = false
                        self.buttonState = ButtonState.play
                        self.indicatorState = .pause
                    } else {
                        self.buttonState = ButtonState.preparing
                    }
                
                case .error:
                    self.isButtonEnabled = true
                    self.showError = true
                    self.buttonState = ButtonState.play
                    self.indicatorState = .pause
                
                case .readyToPlay:
                    if self.alreadyShowed {
                        self.isButtonEnabled = true
                        self.showError = false
                        self.buttonState = ButtonState.play
                        self.indicatorState = .pause
                    } else {
                        self.alreadyShowed = true
                        self.playTapped()
                    }
                    
                case .playing:
                    self.alreadyPlayed = true
                    self.isButtonEnabled = true
                    self.showError = false
                    self.buttonState = ButtonState.pause
                    self.indicatorState = .play
                }
            }
            
            player.$trackTitle.sink { [weak self] in
                self?.trackTitle = $0
            }
        }
    }
            
    func playTapped() {
        switch player.status {
        case .error:
            player.start(url: Config.config.streamUrl)
            player.play()
        case .playing:
            player.pause()
        default:
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
        
    @Published var indicatorState: MusicIndicator.AudioState = .pause
    @Published private(set) var trackTitle = TrackTitle.makeEmpty()
    @Published private(set) var isButtonEnabled = false
    @Published private(set) var buttonState = ButtonState.preparing
    @Published private(set) var showError = false
    
    var buttonImage: String {
        switch buttonState {
        case .preparing:
            return ""
        case .play:
            return "play-dark"
        case .pause:
            return "pause-dark"
        }
    }
    
    // MARK:- private
    
    private var alreadyShowed = false
    private var alreadyPlayed = false
    
    private let player: Player
    private var cancelBag = CancelBag()
}
