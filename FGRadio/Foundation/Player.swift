import Foundation
import Combine
import AVKit

final class Player: NSObject, ObservableObject {
    enum Status {
        case starting
        case readyToPlay
        case error
        case preparingToPlay
        case playing
    }
    
    @Published private(set) var trackTitle = TrackTitle.makeEmpty()
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
        } catch let err {
            print("av player error \(err)")
        }
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
    func metadataOutput(_ output: AVPlayerItemMetadataOutput, didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup], from track: AVPlayerItemTrack?) {
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
