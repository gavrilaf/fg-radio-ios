//
//  ConnectionObserver.swift
//  FGRadio
//
//  Created by Eugen Fedchenko on 19.10.2020.
//  Copyright © 2020 Eugen Fedchenko. All rights reserved.
//

import Foundation
import Reachability

final class ConnectionObserver {
    init(player: Player) throws {
        self.player = player
        self.reachability = try Reachability()
            
        reachability.whenReachable = { [weak self] _ in self?.onRestoreConnection() }
        reachability.whenUnreachable = { [weak self] _ in self?.onLostConnection() }
            
        try reachability.startNotifier()
    }
    
    private func onRestoreConnection() {
        if restorePlaying {
            player.play()
            restorePlaying = false
        }
    }
    
    private func onLostConnection() {
        if player.status == .playing {
            restorePlaying = true
        }
    }
    
    private let reachability: Reachability
    private let player: Player
    
    private var restorePlaying = false
}
