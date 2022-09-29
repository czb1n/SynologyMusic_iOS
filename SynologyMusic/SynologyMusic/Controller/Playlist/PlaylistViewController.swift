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
    
    var playlist: [Song] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tableView.register(cellType: PlaylistSongCell.self)
        self.playlist = SMMusicPlayer.shared.playlist
        self.tableView.reloadData()
    }
}

extension PlaylistViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.playlist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: PlaylistSongCell.self)
        cell.title.text = playlist[indexPath.row].title
        cell.no.text = "\(indexPath.row)"
        return cell
    }
}

extension PlaylistViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let song = self.playlist[indexPath.row]
        SMMusicPlayer.shared.playSong(song)
        SMMusicPlayer.shared.play()
        self.dismiss(animated: true)
    }
}

