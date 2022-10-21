//
//  PlaylistViewController.swift
//  SynologyMusic
//
//  Created by czb1n on 2022/9/29.
//

import UIKit

extension PlaylistViewController: FromMainStoryboard {}

class PlaylistViewController: UIViewController {
    @IBOutlet var tableView: UITableView!

    var playlistKeys: [String] = []
    var playlistKeyFirstIndex: [Int] = []
    var playlist: [String: [Song]] = Dictionary()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tableView.register(cellType: PlaylistSongCell.self)
        self.playlist = Dictionary(grouping: SMMusicPlayer.shared.playlist, by: { [unowned self] m in
            self.findFirstLetter(m.title)
        })
        self.playlistKeys = self.playlist.keys.sorted()

        var count = 0
        self.playlistKeys.forEach { [unowned self] key in
            self.playlistKeyFirstIndex.append(count)
            count = count + (self.playlist[key]?.count ?? 0)
        }
        self.tableView.reloadData()
    }

    func findFirstLetter(_ aString: String) -> String {
        // 转变成可变字符串
        let mutableString = NSMutableString(string: aString)
        // 将中文转换成带声调的拼音
        CFStringTransform(mutableString as CFMutableString, nil, kCFStringTransformToLatin, false)
        // 去掉声调
        let pinyinString = mutableString.folding(options: String.CompareOptions.diacriticInsensitive, locale: NSLocale.current).uppercased()
        // 截取大写首字母
        let firstString = pinyinString.substring(to: pinyinString.index(pinyinString.startIndex, offsetBy: 1))
        // 判断首字母是否为大写
        let regexA = "^[A-Z]$"
        let predA = NSPredicate(format: "SELF MATCHES %@", regexA)
        return predA.evaluate(with: firstString) ? firstString : "#"
    }
}

extension PlaylistViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.playlistKeys.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playlist[self.playlistKeys[section]]?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: PlaylistSongCell.self)
        let song = self.playlist[self.playlistKeys[indexPath.section]]?[indexPath.row]
        cell.noLabel.text = "\(self.playlistKeyFirstIndex[indexPath.section] + indexPath.row)"
        cell.titleLabel.text = song?.title ?? ""
        cell.artistLabel.text = "\(song?.artist ?? "")"
        return cell
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.playlistKeys
    }
}

extension PlaylistViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let song = self.playlist[indexPath.row]
//        Debug.log(self.findFirstLetter(song.title))
//        SMMusicPlayer.shared.playSong(song)
//        SMMusicPlayer.shared.play()
//        self.dismiss(animated: true)
    }
}
