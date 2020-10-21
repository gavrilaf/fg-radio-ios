//
//  ConnectionObserver.swift
//  FGRadio
//
//  Created by Eugen Fedchenko on 19.10.2020.
//  Copyright © 2020 Eugen Fedchenko. All rights reserved.
//

import Foundation
import Reachability
import Combine

final class ConnectionObserver {
    init(player: Player) {
        self.player = player
        
        do {
            self.reachability = try Reachability()
            
            isReachable = reachability?.connection != .unavailable
            
            reachability?.whenReachable = { [weak self] _ in self?.onRestoreConnection() }
            reachability?.whenUnreachable = { [weak self] _ in self?.onLostConnection() }
                
            try reachability?.startNotifier()
            
            if !isReachable {
                onLostConnection()
                restorePlaying = true
            }
        } catch let err {
            print("failed to create reachability, \(err)")
        }
    }
    
    @Published private(set) var isReachable: Bool = true
    
    // MARK:- private
    
    private func onRestoreConnection() {
        isReachable = true
        
        if restorePlaying {
            player.play()
            restorePlaying = false
        }
    }
    
    private func onLostConnection() {
        isReachable = false
        
        if player.status == .playing {
            restorePlaying = true
        }
        
        player.onLostConnection()
    }
    
    private var reachability: Reachability? = nil
    private let player: Player
    
    private var restorePlaying = false
}
