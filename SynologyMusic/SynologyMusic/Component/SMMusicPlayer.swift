//
//  SMMusicPlayer.swift
//  MusicPlayer
//
//  Created by czb1n on 2022/9/29.
//

import AVKit
import MediaPlayer
import RxCocoa
import RxSwift
import UIKit

enum PlayMode {
    case random
    case sequence
}

struct SongWords {
    var time: TimeInterval
    var content: String

    init(original: String) {
        let tStrings = String(original.split(separator: "]")[0][1...]).split(separator: ":")
        let minute = Int64(tStrings[0]) ?? 0
        let second = Int64(tStrings[1].split(separator: ".")[0]) ?? 0
        let milli = Int64(tStrings[1].split(separator: ".")[1]) ?? 0
        self.time = TimeInterval(integerLiteral: minute * 60000 + second * 1000 + milli)

        self.content = original.split(separator: "]").count > 1 ? String(original.split(separator: "]")[1]) : ""
    }
}

struct Song {
    var id: String = ""
    var title: String = ""
    var artist: String = ""
    var artwork: UIImage? = nil
    var albumArtist: String = ""
    var albumTitle: String = ""
    var originalLyric: String = ""
    var lyric: [SongWords] = []
    var url: URL
}

class SMMusicPlayer: AVPlayer {
    static let shared = SMMusicPlayer()

    override init() {
        super.init()

        self.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 10), queue: .main) { [unowned self] time in
            let wordIndex = self.currentSong?.lyric.lastIndex(where: { words in
                time.seconds >= Double(words.time / 1000)
            })
            guard let index = wordIndex else {
                return
            }
            if self.currentLyricIndex != index {
                self.currentLyricIndex = index
                self.setNowPlayingInfoLyric(self.currentSong?.lyric[index].content ?? "")
                self.songLyricIndexChangePublish.onNext(index)
            }
        }

        NotificationCenter.default.rx
            .notification(.AVPlayerItemDidPlayToEndTime)
            .subscribe(onNext: { [unowned self] _ in
                Debug.log("play finished")
                self.playNextSong()
            })
            .disposed(by: self.disposeBag)

//        NotificationCenter.default.rx
//            .notification(AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
//            .subscribe { [unowned self] event in
//                Debug.log("interruption notification")
//                guard let info = event.userInfo,
//                      let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
//                      let type = AVAudioSession.InterruptionType(rawValue: typeValue)
//                else {
//                    return
//                }
//                if type == .began {
//                    // Interruption began, take appropriate actions (save state, update user interface)
//                } else if type == .ended {
//                    guard let optionsValue =
//                        info[AVAudioSessionInterruptionOptionKey] as? UInt
//                    else {
//                        return
//                    }
//                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
//                    if options.contains(.shouldResume) {
//                        // Interruption Ended - playback should resume
//                        Debug.log("interruption end, play again")
//                    }
//                }
//            }
//            .disposed(by: self.disposeBag)
    }

    var playing: Bool = false {
        didSet {
            self.playingPublish.onNext(self.playing)
        }
    }

    var preSong: Song?
    var currentSong: Song?
    var currentSongId: String {
        self.currentSong?.id ?? ""
    }
    var currentLyricIndex: Int?

    var lastPlaySongId: String? {
        get {
            UserDefaults.standard.string(forKey: DataSaveKey.lastPlaySongId.rawValue)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DataSaveKey.lastPlaySongId.rawValue)
        }
    }

    var disposeBag = DisposeBag()
    var playlist: [Song] = []
    var playMode: PlayMode = .random
    var songChangePublish: PublishSubject<Song> = .init()
    var songInfoChangePublish: PublishSubject<Song> = .init()
    var songLyricIndexChangePublish: PublishSubject<Int> = .init()
    var playingPublish: PublishSubject<Bool> = .init()

    func updateArtwork() {
        SMSynologyManager.shared.getSongArtwork(id: self.currentSongId) { [unowned self] artwork in
            self.currentSong?.artwork = artwork
            self.setNowPlayingInfoArtwork()
            self.songInfoChangePublish.onNext(self.currentSong!)
        }
    }

    func updateLyric() {
        SMSynologyManager.shared.getSongLyrics(id: self.currentSongId) { [unowned self] lyric in
            self.currentSong?.lyric = []
            self.currentSong?.originalLyric = lyric ?? ""
            self.currentSong?.originalLyric.replacingOccurrences(of: "\r\n", with: "\n").split(separator: "\n").forEach { [unowned self] sub in
                let str = String(sub)
                guard let _ = str.range(of: "\\[\\d+:\\d+\\.\\d+\\].*", options: .regularExpression) else {
                    return
                }
                let words = SongWords(original: str)
                if !words.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.currentSong?.lyric.append(words)
                }
            }
            self.songInfoChangePublish.onNext(self.currentSong!)
        }
    }

    func playSong(_ song: Song) {
        Debug.log("play song \(song.title)")
        self.preSong = self.currentSong
        self.currentSong = song
        self.lastPlaySongId = song.id
        let item = AVPlayerItem(asset: AVURLAsset(url: song.url, options: [AVURLAssetHTTPCookiesKey: HTTPCookieStorage.shared.cookies!]))
        self.updateLyric()
        self.updateArtwork()
        self.replaceCurrentItem(with: item)
        self.songChangePublish.onNext(self.currentSong!)
        self.currentItem?.rx
            .observeWeakly(Int.self, "status")
            .subscribe { [unowned self] value in
                Debug.log("player item status = \(value)")
                if value.element == 1 {
                    self.setNowPlayingStatisicInfo()
                    if self.playing {
                        self.play()
                    }
                }
            }
            .disposed(by: self.disposeBag)
    }

    func playPreSong() {
        guard let preSong = self.preSong else {
            return
        }
        self.playing = true
        self.playSong(preSong)
    }

    func playNextSong() {
        if self.playlist.isEmpty {
            return
        }
        self.playing = true
        if self.playMode == .random {
            self.playSong(self.playlist.randomElement()!)
        } else {
            let currentIndex = self.playlist.firstIndex { [unowned self] s in
                s.id == self.currentSongId
            } ?? 0
            let nextIndex = (currentIndex + 1) % self.playlist.count
            self.playSong(self.playlist[nextIndex])
        }
    }

    override func pause() {
        super.pause()
        MPNowPlayingInfoCenter.default().playbackState = .paused
        self.setNowPlayingStatisicInfo()
        self.playing = false
    }

    override func play() {
        super.play()
        MPNowPlayingInfoCenter.default().playbackState = .playing
        self.setNowPlayingStatisicInfo()
        self.setRemoteCommand()
        self.playing = true
    }

    func playOrPause() {
        if self.playing {
            self.pause()
        } else {
            self.play()
        }
    }

    func unsetRemoteCommand() {
        MPRemoteCommandCenter.shared().playCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().pauseCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().nextTrackCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().previousTrackCommand.removeTarget(nil)
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.removeTarget(nil)
    }

    func setRemoteCommand() {
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget { _ in
            .success
        }
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget { _ in
            .success
        }
        MPRemoteCommandCenter.shared().playCommand.addTarget { _ in
            .success
        }
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { _ in
            .success
        }
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand.addTarget { [unowned self] e in
            guard let event = (e as? MPChangePlaybackPositionCommandEvent) else {
                return .commandFailed
            }
            Debug.log(event.positionTime)
            self.seek(to: CMTime(seconds: event.positionTime, preferredTimescale: CMTimeScale(1000))) { _ in
            }
            return .success
        }
    }

    func setNowPlayingInfoArtwork() {
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()

        if self.currentSong?.artwork != nil {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: self.currentSong!.artwork!.size, requestHandler: { _ in self.currentSong!.artwork! })
        }

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

    func setNowPlayingInfoLyric(_ lyric: String) {
        guard let item = self.currentItem else {
            return
        }
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
        if lyric.isEmpty || lyric == (nowPlayingInfo[MPMediaItemPropertyTitle] as? String ?? "") {
            return
        }

        nowPlayingInfo[MPMediaItemPropertyTitle] = lyric
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(item.currentTime())
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }

    func setNowPlayingStatisicInfo() {
        guard let item = self.currentItem else {
            return
        }

        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()

        nowPlayingInfo[MPNowPlayingInfoPropertyAssetURL] = self.currentSong?.url
        nowPlayingInfo[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        nowPlayingInfo[MPMediaItemPropertyTitle] = self.currentSong?.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = self.currentSong?.artist
        if self.currentSong?.artwork != nil {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: self.currentSong!.artwork!.size, requestHandler: { _ in self.currentSong!.artwork! })
        }
        nowPlayingInfo[MPMediaItemPropertyAlbumArtist] = self.currentSong?.albumArtist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = self.currentSong?.albumTitle
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(item.duration)
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.rate
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = CMTimeGetSeconds(item.currentTime())

        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
}
