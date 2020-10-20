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
            
            player.observe(\.status) { [weak self] _, value in
                guard let self = self else { return }
                                
                print("player status: \(value)")
                
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
                
                print("player observer timecontrol status: \(self.player.timeControlStatus.rawValue), \(String(describing: self.player.error))")
                
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
        
        self.recreatePlayerItem = true
        
        checkIsPlaying?.cancel()
        checkIsPlaying = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            if self.player.timeControlStatus != .playing {
                self.status = .error
            }
        }
        
        // If radio won't start playing after 7 seconds, show an error
        DispatchQueue.main.asyncAfter(deadline: .now() + 7, execute: self.checkIsPlaying!)
    }
    
    func pause() {
        recreatePlayerItem = false
        checkIsPlaying?.cancel()
        player.pause()
    }
    
    func onLostConnection() {
        recreatePlayerItem = true
    }
    
    // MARK:- private
    
    private func setupPlayerItem() {
        print("setupPlayerItem")
        
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
        
        nowPlayingInfo[MPMediaItemPropertyArtist] = trackTitle.title
        nowPlayingInfo[MPMediaItemPropertyTitle] = trackTitle.subtitle

        if let image = UIImage(named: "logo-dark") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in return image }
        }

        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private var player: AVPlayer!
    private var checkIsPlaying: DispatchWorkItem?
    private var observationsBag = ObservationsBag()
    
    private var recreatePlayerItem = false
}

extension Player: AVPlayerItemMetadataOutputPushDelegate {
    func metadataOutput(_ output: AVPlayerItemMetadataOutput,
                        didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
                        from track: AVPlayerItemTrack?) {
        print("mediaOutput....")
        groups.forEach { (group) in
            group.items.forEach { (item) in
                guard let id = item.identifier, let value = item.stringValue else { return }
                
                switch id {
                case AVMetadataIdentifier.icyMetadataStreamTitle:
                    if value.count > 0 {
                        print("title, old: \(trackTitle), new: \(value)")
                        trackTitle = TrackTitle.makeFrom(streamTitle: value)
                    }
                default:
                    print("other value \(id)")
                    break
                }
            }
        }
    }
}
