//
//  HomeViewController.swift
//  SynologyMusic
//
//  Created by czb1n on 2022/9/29.
//

import MediaPlayer
import RxCocoa
import RxSwift
import Toast_Swift
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
    @IBOutlet var lyricTableView: UITableView!
    
    var lyrics: [SongWords] = []
    var primaryIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        artworkImageView.layer.masksToBounds = true
        artworkImageView.layer.cornerRadius = 125.0
        
        self.lyricTableView.register(cellType: LyricCell.self)
        
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
        
        SMMusicPlayer.shared.songLyricIndexChangePublish.subscribe { [unowned self] e in
            let index = e.element ?? 0
            self.primaryIndex = index
            self.lyricTableView.reloadData()
            scrollToLyricIndex(index - 2)
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
        self.lyrics = song?.lyric ?? []
        self.lyricTableView.reloadData()
        self.scrollToLyricIndex(0)
    }
    
    func scrollToLyricIndex(_ index: Int) {
        if index >= 0, self.lyrics.count > index {
            self.lyricTableView.scrollToRow(at: .init(row: index, section: 0), at: .top, animated: true)
        }
    }
    
    func judgeSynologyLoginState() {
        SMSynologyManager.shared.login { [unowned self] success in
            if success {
                Debug.log("login success")
                self.view.makeToast("登录成功", position: .center)
            } else {
                let vc = LoginViewController.instantiate()
                vc.view.makeToast("请先登录", position: .center)
                self.present(vc, animated: true)
            }
        }
    }
}

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.lyrics.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: LyricCell.self)
        cell.contentLabel.text = self.lyrics[indexPath.row].content
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == self.primaryIndex {
            (cell as! LyricCell).toPrimaryStyle()
        } else if indexPath.row == self.primaryIndex - 1 || indexPath.row == self.primaryIndex + 1 {
            (cell as! LyricCell).toSecondaryStyle()
        } else {
            (cell as! LyricCell).toCommonStyle()
        }
    }
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30.0
    }
}
