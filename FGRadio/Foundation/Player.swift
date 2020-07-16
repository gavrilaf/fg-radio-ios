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
            print("Updated track title \(trackTitle)")
            setupNowPlaying()
        }
    }
    
    @Published private(set) var status: Status = .starting
    
    init(url: URL) {
        self.url = url
    }
    
    func start() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            player = AVPlayer(url: url)
            
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
            print("av player error \(err)")
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
    }
    
    func pause() {
        player.pause()
    }
    
    // MARK:- private
    
    private let url: URL
    private var player: AVPlayer!
    private var observationsBag = ObservationsBag()
}

extension Player: AVPlayerItemMetadataOutputPushDelegate {
    func metadataOutput(_ output: AVPlayerItemMetadataOutput,
                        didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
                        from track: AVPlayerItemTrack?) {
        print("updated metadata output")
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
