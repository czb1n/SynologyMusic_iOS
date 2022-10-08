//
//  AppDelegate.swift
//  SynologyMusic
//
//  Created by czb1n on 2022/9/29.
//

import UIKit
import AVKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        application.beginReceivingRemoteControlEvents()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let err {
            Debug.log(err)
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }

    override func remoteControlReceived(with event: UIEvent?) {
        Debug.log(event)
        switch event?.subtype {
        case .remoteControlPlay:
            Debug.log("remote control play")
            SMMusicPlayer.shared.playOrPause()
        case .remoteControlPause:
            Debug.log("remote control pause")
            SMMusicPlayer.shared.playOrPause()
        case .remoteControlStop:
            Debug.log("remote control stop")
            SMMusicPlayer.shared.playOrPause()
        case .remoteControlNextTrack:
            Debug.log("remote control next")
            SMMusicPlayer.shared.playNextSong()
        case .remoteControlPreviousTrack:
            Debug.log("remote control pre")
            SMMusicPlayer.shared.playPreSong()
        default:
            break
        }
    }
}

