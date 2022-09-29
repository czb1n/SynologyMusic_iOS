//
//  SMSynologyManager.swift
//  SynologyMusic
//
//  Created by czb1n on 2022/9/29.
//

import Alamofire
import Foundation
import RxAlamofire
import RxSwift

class SMSynologyManager {
    static let SynologyHostSaveKey = ""

    static let shared = SMSynologyManager(
        host: UserDefaults.standard.string(forKey: DataSaveKey.synologyHost.rawValue) ?? "",
        port: UserDefaults.standard.integer(forKey: DataSaveKey.synologyPort.rawValue),
        account: UserDefaults.standard.string(forKey: DataSaveKey.synologyAccount.rawValue) ?? "",
        password: UserDefaults.standard.string(forKey: DataSaveKey.synologyPassword.rawValue) ?? ""
    )

    var host: String {
        didSet {
            UserDefaults.standard.set(host, forKey: DataSaveKey.synologyHost.rawValue)
        }
    }

    var port: Int {
        didSet {
            UserDefaults.standard.set(port, forKey: DataSaveKey.synologyPort.rawValue)
        }
    }

    var account: String {
        didSet {
            UserDefaults.standard.set(account, forKey: DataSaveKey.synologyAccount.rawValue)
        }
    }

    var password: String {
        didSet {
            UserDefaults.standard.set(password, forKey: DataSaveKey.synologyPassword.rawValue)
        }
    }

    var isLogin: Bool = false
    var sid: String = ""
    var synotoken: String = ""
    
    var loginSuccessPublish: PublishSubject<String> = .init()

    let disposeBag: DisposeBag = .init()

    var requestHost: String {
        if port <= 0 {
            return host
        }
        return "\(host):\(port)"
    }

    var requestHeader: HTTPHeaders {
        return HTTPHeaders(["Cookie": "id=\(sid)", "X-SYNO-TOKEN": synotoken])
    }

    init(host: String, port: Int, account: String, password: String) {
        self.host = host
        self.port = port
        self.account = account
        self.password = password
    }

    func login(completionHandler: @escaping (Bool) -> Void) {
        let params = "api=SYNO.API.Auth&version=3&method=login&account=\(account)&passwd=\(password)&session=audiostation&format=cookie&enable_syno_token=yes".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(requestHost)/webapi/auth.cgi?\(params)"
        guard let url = URL(string: urlString), let req = try? URLRequest(url: url, method: .get) else {
            completionHandler(false)
            return
        }
        URLSession.shared.rx
            .data(request: req)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] data in
                let json = data.toDictionary()
                Debug.log("login synology response : \(json)")
                if !json.bool("success") {
                    self.isLogin = false
                    completionHandler(false)
                } else {
                    self.sid = json.dic("data").str("sid")
                    self.synotoken = json.dic("data").str("synotoken")
                    let properties: [HTTPCookiePropertyKey: Any] = [
                        HTTPCookiePropertyKey.domain: "Domain=\(host)",
                        HTTPCookiePropertyKey.path: "/",
                        HTTPCookiePropertyKey.secure: true,
                        HTTPCookiePropertyKey("HttpOnly"): true,
                        HTTPCookiePropertyKey.value: sid,
                        HTTPCookiePropertyKey.name: "id"
                    ]
                    HTTPCookieStorage.shared.setCookie(HTTPCookie(properties: properties)!)
                    self.isLogin = true
                    self.loginSuccessPublish.onNext(self.sid)
                    completionHandler(true)
                }
            }, onError: { _ in
                completionHandler(false)
            })
            .disposed(by: disposeBag)
    }

    func getSongLyrics(id: String, completionHandler: @escaping (String?) -> Void) {
        let params = "api=SYNO.AudioStation.Lyrics&method=getlyrics&id=\(id)&version=2".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(requestHost)/webapi/AudioStation/lyrics.cgi?\(params)"
        guard let url = URL(string: urlString), let req = try? URLRequest(url: url, method: .get, headers: requestHeader) else {
            return
        }
        URLSession.shared.rx
            .data(request: req)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { data in
                completionHandler(data.toDictionary().dic("data").str("lyrics"))
            })
            .disposed(by: disposeBag)
    }

    func getSongArtwork(id: String, completionHandler: @escaping (UIImage?) -> Void) {
        let params = "api=SYNO.AudioStation.Cover&output_default=true&is_hr=false&version=3&library=shared&_dc=\(Date.now.timeIntervalSince1970)&method=getsongcover&view=playing&id=\(id)&SynoToken=\(synotoken)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(requestHost)/webapi/AudioStation/cover.cgi?\(params)"
        guard let url = URL(string: urlString), let req = try? URLRequest(url: url, method: .get, headers: requestHeader) else {
            return
        }
        URLSession.shared.rx
            .data(request: req)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { data in
                completionHandler(UIImage(data: data))
            })
            .disposed(by: disposeBag)
    }

    func getSongs(offset: Int, limit: Int, completionHandler: @escaping ([Song]) -> Void) {
        let params = "limit=\(limit)&method=list&library=shared&api=SYNO.AudioStation.Song&additional=song_tag,song_audio,song_rating&version=3&sort_by=title&sort_direction=ASC".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(requestHost)/webapi/AudioStation/song.cgi?\(params)"
        Debug.log("songs url \(urlString)")
        guard let url = URL(string: urlString), let req = try? URLRequest(url: url, method: .get, headers: requestHeader) else {
            return
        }
        URLSession.shared.rx
            .data(request: req)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] data in
                let json = data.toDictionary()
//                Debug.log("get synology songs success response : \(json)")
                let songs: [Song] = json.dic("data").dicArray("songs").map { [unowned self] song in
                    Song(
                        id: song.str("id"),
                        title: song.str("title"),
                        artist: song.dic("additional").dic("song_tag").str("artist"),
                        albumArtist: song.dic("additional").dic("song_tag").str("album_artist"),
                        albumTitle: song.dic("additional").dic("song_tag").str("alb"),
                        url: URL(string: "\(self.requestHost)/webapi/AudioStation/stream.cgi/0.mp3?sid=\(self.sid)&api=SYNO.AudioStation.Stream&version=2&method=stream&id=\(song.str("id"))&_dc=\(Date.now.timeIntervalSince1970)&SynoToken=\(self.synotoken)")!
                    )
                }
                completionHandler(songs)
            })
            .disposed(by: disposeBag)
    }
}
