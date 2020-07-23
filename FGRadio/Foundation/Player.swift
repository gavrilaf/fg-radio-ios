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
    
    private enum Const {
        static let volumeChangedNotification    = NSNotification.Name("AVSystemController_SystemVolumeDidChangeNotification")
        static let volumeLevelParam             = "AVSystemController_AudioVolumeNotificationParameter"
        static let volumeChangeReasonParam      = "AVSystemController_AudioVolumeChangeReasonNotificationParameter"
        static let reasonExplicit               = "ExplicitVolumeChange"
    }
    
    @Published private(set) var trackTitle = TrackTitle.makeEmpty() {
        didSet {
            setupNowPlaying()
        }
    }
    
    @Published var volume: Float = 0.5 {
        didSet {
            volumeView.setVolume(volume)
        }
    }
    
    @Published private(set) var status: Status = .starting
    
    init(url: URL) {
        self.url = url
        super.init()
        
        //Add observer for the volume change event
        NotificationCenter.default.addObserver(self, selector: #selector(volumeChanged), name: Const.volumeChangedNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Const.volumeChangedNotification, object: nil)
    }
    
    func start() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            
            try audioSession.setCategory(AVAudioSession.Category.playback)
            player = AVPlayer(url: url)
            
            volume = audioSession.outputVolume
            
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
    }
    
    func pause() {
        player.pause()
    }
    
    // MARK:- private
    
    @objc func volumeChanged(notification: NSNotification) {
        guard
            let info = notification.userInfo,
            let reason = info[Const.volumeChangeReasonParam] as? String,
            reason == Const.reasonExplicit,
            let volume = info[Const.volumeLevelParam] as? Float else { return }
        
        self.volume = volume
    }
    
    private let url: URL
    private var player: AVPlayer!
    private let volumeView = MPVolumeView()
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
