import Foundation
import Combine
import AVKit
import MediaPlayer

final class Player: NSObject, ObservableObject {
    enum Status {
        case starting
        case readyToPlay
        case error
        case preparingToPlay
        case playing
    }
        
    @Published private(set) var trackTitle = TrackTitle.makeEmpty() {
        didSet {
            setupNowPlaying()
        }
    }
        
    @Published private(set) var status: Status = .starting
    
    override init() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSession.Category.playback)
            
            player = AVPlayer()
            
            super.init()
            
            player.observe(\.status) { [weak self] _, _ in
                self?.playerStatusDidUpdate()
            }.store(in: &observationsBag)
            
            player.observe(\.timeControlStatus) { [weak self] _, _ in
                self?.timeControlStatusDidUpdate()
            }.store(in: &observationsBag)
                        
            setupRemoteTransportControls()
            
            status = .readyToPlay
        } catch let err {
            fatalError("AV session error \(err)")
        }
    }
    
    func start(autoplay: Bool) {
        setupPlayerItem()
        if autoplay {
            play()
        }
    }
    
    func play() {
        if recreatePlayerItem || player.currentItem == nil {
            setupPlayerItem()
        }
        
        player.play()
        checkErrorAndRetry()
    }
    
    func pause() {
        recreatePlayerItem = false
        cancelCheckError()
        player.pause()
    }
    
    func onLostConnection() {
        recreatePlayerItem = true
        cancelCheckError()
    }
    
    // MARK:- private
    
    private func setupPlayerItem() {
        print("open stream url: \(Config.shared.streamUrl)")
        
        let playerItem = AVPlayerItem(url: Config.shared.streamUrl)
        
        let metadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
        metadataOutput.setDelegate(self, queue: DispatchQueue.main)
        playerItem.add(metadataOutput)
        
        player.replaceCurrentItem(with: playerItem)
        self.recreatePlayerItem = false
    }
    
    private func setupRemoteTransportControls() {
        // Get the shared MPRemoteCommandCenter
        let commandCenter = MPRemoteCommandCenter.shared()

        // Add handler for Play Command
        commandCenter.playCommand.addTarget { [unowned self] event in
            if self.status == .readyToPlay {
                self.play()
                return .success
            }
            return .commandFailed
        }

        // Add handler for Pause Command
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.status == .playing {
                self.pause()
                return .success
            }
            return .commandFailed
        }
    }
    
    private func setupNowPlaying() {
        var nowPlayingInfo = [String : Any]()
        
        nowPlayingInfo[MPMediaItemPropertyArtist] = trackTitle.isTitleEmpty ? "" : trackTitle.title
        nowPlayingInfo[MPMediaItemPropertyTitle] = trackTitle.isSubtitleEmpty ? "" : trackTitle.subtitle

        if let image = UIImage(named: "logo-dark") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in return image }
        }

        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func checkErrorAndRetry() {
        checkIsPlaying = DispatchWorkItem { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if self.player.timeControlStatus != .playing {
                    if self.retryCount >= 2 {
                        self.status = .error
                        self.retryCount = 0
                    } else {
                        self.retryCount += 1
                        self.recreatePlayerItem = true
                        
                        DispatchQueue.main.async {
                            self.play()
                        }
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: self.checkIsPlaying!)
    }
    
    private func cancelCheckError() {
        checkIsPlaying?.cancel()
        checkIsPlaying = nil
    }
    
    private func playerStatusDidUpdate() {
        switch player.status {
        case .unknown:
            status = .starting
        case .failed:
            status = .error
        case .readyToPlay:
            status = .readyToPlay
        @unknown default:
            fatalError("update application")
        }
    }
    
    private func timeControlStatusDidUpdate() {
        switch player.timeControlStatus {
        case .waitingToPlayAtSpecifiedRate:
            status = .preparingToPlay
        case .paused:
            status = .readyToPlay
        case .playing:
            status = .playing
        @unknown default:
            fatalError("update application")
        }
        
        if status == .playing {
            self.cancelCheckError()
            self.recreatePlayerItem = true
            self.retryCount = 0
        }
    }
    
    // MARK:- private state
    
    private var player: AVPlayer!
    private var checkIsPlaying: DispatchWorkItem?
    private var observationsBag = ObservationsBag()
    
    private var recreatePlayerItem = false
    private var retryCount = 0
}

extension Player: AVPlayerItemMetadataOutputPushDelegate {
    func metadataOutput(_ output: AVPlayerItemMetadataOutput,
                        didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
                        from track: AVPlayerItemTrack?) {
        groups.forEach { (group) in
            group.items.forEach { (item) in
                guard let id = item.identifier, let value = item.stringValue else { return }
                
                switch id {
                case AVMetadataIdentifier.icyMetadataStreamTitle:
                    if !value.isEmpty {
                        trackTitle = TrackTitle.makeFrom(streamTitle: value)
                    }
                default:
                    break
                }
            }
        }
    }
}
