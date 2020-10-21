//
//  PlayerViewModel.swift
//  FGRadio
//
//  Created by Eugen Fedchenko on 20.06.2020.
//  Copyright © 2020 Eugen Fedchenko. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
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
    
    init(player: Player, reachability: ConnectionObserver) {
        self.player = player
        self.reachability = reachability
        
        cancelBag.collect {
            player.$status
                .debounce(for: 0.2, scheduler: RunLoop.main)
                .sink { [weak self] (status) in
                    self?.update(status: status)
                }
            
            
            player.$trackTitle.sink { [weak self] in
                self?.trackTitle = $0
            }
            
            reachability.$isReachable
                .debounce(for: 0.2, scheduler: RunLoop.main)
                .sink { [weak self] (reachable) in
                    print("reachability is reachable")
                    self?.showBanner = !reachable
                }
        }
    }
            
    func playTapped() {
        switch player.status {
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
            url = Config.shared.intstagramUrl
        case .fb:
            if UIApplication.shared.canOpenURL(Config.shared.fbAppUrl) {
                url = Config.shared.fbAppUrl
            } else {
                url = Config.shared.fbUrl
            }
        case .youTube:
            url = Config.shared.youtubeUrl
        case .site:
            url = Config.shared.siteUrl
        }
        
        UIApplication.shared.open(url)
    }
    
    func callStudio() {
        UIApplication.shared.open(Config.shared.studioPhone)
    }
    
    func chatStudio() {
        let tgUrl = Config.shared.tgLink
        if UIApplication.shared.canOpenURL(tgUrl) {
            UIApplication.shared.open(tgUrl)
        }
    }
        
    @Published private(set) var trackTitle = TrackTitle.makeEmpty()
    @Published private(set) var isButtonEnabled = false
    @Published private(set) var buttonState = ButtonState.preparing
    @Published private(set) var playingAnimation = false
    @Published private(set) var showError = false
    @Published private(set)var showBanner = false
    
    
    
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
    private func update(status: Player.Status) {
        switch status {
        case .starting:
            self.playingAnimation = false
            self.isButtonEnabled = false
            self.showError = false
            self.buttonState = ButtonState.preparing
        
        case .preparingToPlay:
            self.playingAnimation = false
            self.isButtonEnabled = false
            self.showError = false
            self.buttonState = ButtonState.preparing
        
        case .error:
            self.playingAnimation = false
            self.isButtonEnabled = true
            self.showError = true
            self.buttonState = ButtonState.play
        
        case .readyToPlay:
            self.playingAnimation = false
            self.isButtonEnabled = true
            self.showError = false
            self.buttonState = ButtonState.play

        case .playing:
            self.playingAnimation = true
            self.isButtonEnabled = true
            self.showError = false
            self.buttonState = ButtonState.pause
        }
        print("viewState: button \(self.buttonState) indicator \(self.playingAnimation)")
    }
    
    private let player: Player
    private let reachability: ConnectionObserver
    
    private var cancelBag = CancelBag()
}
