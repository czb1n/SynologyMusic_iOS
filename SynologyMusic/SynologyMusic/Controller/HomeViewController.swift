//
//  HomeViewController.swift
//  SynologyMusic
//
//  Created by czb1n on 2022/9/29.
//

import MediaPlayer
import RxCocoa
import RxSwift
import UIKit

class HomeViewController: UIViewController {
    var disposeBag = DisposeBag()

    @IBOutlet var songTitleLabel: UILabel!
    @IBOutlet var songArtistLabel: UILabel!
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var artworkImageView: UIImageView!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var prePlayButton: UIButton!
    @IBOutlet var nextPlayButton: UIButton!
    @IBOutlet var playlistButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.playlistButton.rx.tap.subscribe { [unowned self] _ in
            let vc = PlaylistViewController.instantiate()
            self.present(vc, animated: true)
        }.disposed(by: self.disposeBag)

        self.playButton.rx.tap.subscribe { _ in
            SMMusicPlayer.shared.playOrPause()
        }.disposed(by: self.disposeBag)

        self.prePlayButton.rx.tap.subscribe { _ in
            SMMusicPlayer.shared.playPreSong()
        }.disposed(by: self.disposeBag)

        self.nextPlayButton.rx.tap.subscribe { _ in
            SMMusicPlayer.shared.playNextSong()
        }.disposed(by: self.disposeBag)
        
        let backgroundEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        backgroundEffectView.frame = self.view.frame
        self.backgroundImageView.addSubview(backgroundEffectView)
        
        SMMusicPlayer.shared.songChangePublish.subscribe { [unowned self] song in
            self.updateCurrentSongInfo(song)
        }.disposed(by: self.disposeBag)
        
        SMMusicPlayer.shared.songInfoChangePublish.subscribe { [unowned self] song in
            self.updateCurrentSongInfo(song)
        }.disposed(by: self.disposeBag)
        
        SMMusicPlayer.shared.playingPublish.subscribe { [unowned self] value in
            if value.element == true {
                self.playButton.setImage(Asset.pause.image, for: .normal)
            } else {
                self.playButton.setImage(Asset.play.image, for: .normal)
            }
        }.disposed(by: self.disposeBag)
        
        SMSynologyManager.shared.loginSuccessPublish.subscribe(onNext: { _ in
            SMSynologyManager.shared.getSongs(offset: 0, limit: 5000) { songs in
                SMMusicPlayer.shared.playlist = songs
                guard let song = songs.first(where: { song in song.id == SMMusicPlayer.shared.lastPlaySongId }) else {
                    return
                }
                SMMusicPlayer.shared.playSong(song)
            }
        }).disposed(by: self.disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.judgeSynologyLoginState()
    }
    
    func updateCurrentSongInfo(_ song: Song?) {
        self.songTitleLabel.text = song?.title
        self.songArtistLabel.text = song?.artist
        self.artworkImageView.image = song?.artwork
        self.backgroundImageView.image = song?.artwork
    }
    
    func judgeSynologyLoginState() {
        SMSynologyManager.shared.login { [unowned self] success in
            if success {
                Debug.log("login success")
            } else {
                let vc = LoginViewController.instantiate()
                self.present(vc, animated: true)
            }
        }
    }
}
