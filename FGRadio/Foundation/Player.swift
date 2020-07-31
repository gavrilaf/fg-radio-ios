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
    
    func start(url: URL) {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            try audioSession.setCategory(AVAudioSession.Category.playback)
            
            let playerItem = AVPlayerItem(url: url)
            player = AVPlayer(playerItem: playerItem)
            
            let metadataOutput = AVPlayerItemMetadataOutput(identifiers: nil)
            metadataOutput.setDelegate(self, queue: DispatchQueue.main)
            
            player.currentItem?.add(metadataOutput)
            
            player.observe(\.status) { [weak self] _, _ in
                guard let self = self else { return }
                                
                switch self.player.status {
                case .unknown:
                    self.status = .starting
                case .failed:
                    self.status = .error
                case .readyToPlay:
                    self.status = .readyToPlay
                @unknown default:
                    fatalError("update application")
                }
            }.store(in: &observationsBag)
            
            player.observe(\.timeControlStatus) { [weak self] _, _ in
                guard let self = self else { return }
                
                print("status: \(self.player.timeControlStatus.rawValue)")
                
                switch self.player.timeControlStatus {
                case .waitingToPlayAtSpecifiedRate:
                    self.status = .preparingToPlay
                case .paused:
                    self.status = .readyToPlay
                case .playing:
                    self.status = .playing
                @unknown default:
                    fatalError("update application")
                }
            }.store(in: &observationsBag)
                        
            setupRemoteTransportControls()
        } catch let err {
            fatalError("AV session error \(err)")
        }
    }
    
    func setupRemoteTransportControls() {
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
    
    func setupNowPlaying() {
        var nowPlayingInfo = [String : Any]()
        
        nowPlayingInfo[MPMediaItemPropertyArtist] = trackTitle.title
        nowPlayingInfo[MPMediaItemPropertyTitle] = trackTitle.subtitle

        if let image = UIImage(named: "logo-dark") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in return image }
        }

        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func play() {
        player.play()
        
        self.checkIsPlaying = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            if self.player.timeControlStatus != .playing {
                self.status = .error
            }
        }
        
        // If radio won't start playing after 3 seconds, show an error
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: self.checkIsPlaying!)
    }
    
    func pause() {
        self.checkIsPlaying?.cancel()
        
        player.pause()
    }
    
    // MARK:- private
    private var player: AVPlayer!
    private var checkIsPlaying: DispatchWorkItem?
    private var observationsBag = ObservationsBag()
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
                    if value.count > 0 {
                        trackTitle = TrackTitle.makeFrom(streamTitle: value)
                    }
                default:
                    break
                }
            }
        }
    }
}
