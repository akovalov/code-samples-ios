//
//  AudioPlayer.swift
//
//
//  Created by Alex Kovalov on 11/4/17.
//  Copyright © 2017 . All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import MediaPlayer

import SDWebImage

class AudioPlayer: NSObject {
    
    static var shared = AudioPlayer()
    
    @objc
    enum AudioManagerState: Int {
        
        case none = 0
        case playing
        case pause
        case stop
    }
    
    
    // MARK: Properties
    
    dynamic var currentTime: Int = 0
    dynamic var state: AudioManagerState = .none
    dynamic var currentAudio : Audio? {
        willSet {
            pause()
        }
        didSet {
            if currentAudio != nil && oldValue != nil && currentAudio?.id == oldValue?.id {
                return
            }
            setup(forAudio: currentAudio)
        }
    }
    
    fileprivate var player: AVAudioPlayer?
    fileprivate var listenTime: Double = 0 {
        didSet {
            syncListenTime()
        }
    }
    fileprivate var lastListenedDate: Date?
    fileprivate var updatePlayingTimeTimer: Timer?
    
    
    // MARK: Lifecycle
    
    override init() {
        super.init()
        
        addNotificationObservers()
    }
    
    
    // MARK: Actions
    
    func play(audio: Audio? = nil, autoplay: Bool? = nil) {
        
        func startPlaying() {
            
            if var historyStopTime = currentAudio?.historyStopTime {
                
                if let duration = currentAudio?.duration, (duration - historyStopTime) < 10 {
                    historyStopTime = 0
                }
                
                currentTime = historyStopTime
                player?.currentTime = TimeInterval(currentTime)
            }
            
            player?.play()
            state = .playing
            
            startUpdatePlayingTimeTimer()
            updateCurrentTimeInNowPlayingInfoCenter()
            
            AnalyticsManager.shared.trackPlayAudio(currentAudio)
            AudioManager.shared.pingListen(currentAudio!)
        }
        
        if audio == nil {
            startPlaying()
        }
        else {
            let shouldAutoStartPlaying = (state == .playing || autoplay == true) && audio?.downloaded == true
            currentAudio = audio
            shouldAutoStartPlaying ? startPlaying() : AudioViewController.shared.show()
        }
    }
    
    func startChangePlayingAudioTime() {
        
        stopUpdatePlayingTimeTimer()
    }
    
    func changePlayingAudioTime(_ time: Int) {
        
        guard player != nil else {
            return
        }
        var normalizedTime = TimeInterval(time)
        if normalizedTime < 0 { normalizedTime = 0 }
        else if normalizedTime > player!.duration { normalizedTime = player!.duration }
        
        currentTime = Int(normalizedTime)
        player?.currentTime = TimeInterval(currentTime)
        saveStopTime()
        
        updateCurrentTimeInNowPlayingInfoCenter()
    }
    
    func stopChangePlayingAudioTime() {
        
        startUpdatePlayingTimeTimer()
    }
    
    func pause() {
        
        player?.pause()
        
        stopUpdatePlayingTimeTimer()
        syncListenTime(forced: true)
        
        saveStopTime()
        
        if let historyStopTime = currentAudio?.historyStopTime {
            currentTime = historyStopTime
        }
        
        state = .pause
    }
    
    func togglePlayPause() {
        
        AudioPlayer.shared.state == .playing ? pause() : play()
    }
    
    func playNextAudioInUnion() {
        
        guard SettingsManager.shared.autoPlayNextAudioInUnion, let union = currentAudio?.union else {
            return
        }
        
        let results = union.audios.sorted(byKeyPath: "numberInUnion")
        let audiosInUnion = Array(results)
        
        guard let currentAudioInAnArray = audiosInUnion.filter({ $0.id == currentAudio!.id }).first else { return }
        guard let index = audiosInUnion.index(of: currentAudioInAnArray) else { return }
        
        let nextIndex = index + 1
        guard nextIndex < audiosInUnion.count else { return }
        
        let nextAudio = audiosInUnion[nextIndex]
        guard nextAudio.downloaded else { return }
        
        // play next audio always from the beginning 
        DatabaseManager.shared.change {
            nextAudio.historyStopTime = 0
            nextAudio.historyStopPercentage = 0
        }
        
        play(audio: nextAudio, autoplay: true)
    }
    
    
    // MARK: Private Actions
    
    fileprivate func setup(forAudio audio: Audio?) {
        
        setupAVPlayer(forAudio: audio)
        setupInfoCenter(forAudio: audio)
        
        state = audio == nil ? .none : .stop
        
        AnalyticsManager.shared.trackSelectionAudio(audio)
    }
    
    fileprivate func syncListenTime(forced: Bool = false) {
        
        guard let audio = currentAudio, (listenTime >= 10 || forced) else {
            return
        }
        
        let time = listenTime
        listenTime = 0
        
        let stopTime = currentTime
        
        DatabaseManager.shared.change {
            let roundedTime = time.rounded(.toNearestOrAwayFromZero)
            audio.updateListenTime(listenTime: Int(roundedTime), stopTime: stopTime)
        }
        
        HistoryManager.shared.trackListenTime(time, stopTime: stopTime, forAudio: audio)
    }
    
    fileprivate func saveStopTime() {
        
        guard let audio = currentAudio else {
            return
        }
        
        DatabaseManager.shared.change {
            audio.updateListenTime(listenTime: 0, stopTime: currentTime)
        }
    }
    
    fileprivate func setupAVPlayer(forAudio audio: Audio?) {
        
        guard audio != nil else {
            return
        }
        
        player = nil
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        let url = FileUtils.fileUrl(forAudio: audio!)
        
        player = try? AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        player?.prepareToPlay()
        
        currentTime = audio!.historyStopTime
        player?.currentTime = TimeInterval(currentTime)
    }
}


// MARK: AVAudioPlayerDelegate

extension AudioPlayer: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        pause()
        
        if flag {
            playNextAudioInUnion()
        }
    }
}


// MARK: Observers

extension AudioPlayer {
    
    func addNotificationObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(AudioPlayer.downloadManagerDidFinishDownloading(_:)), name: NSNotification.Name(rawValue: DownloadManagerDidFinishDownloadingNotification), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    func downloadManagerDidFinishDownloading(_ notification: Notification) {
        
        guard let downloadedAudio = notification.object as? Audio, downloadedAudio.id == currentAudio?.id else {
            return
        }
        
        setup(forAudio: currentAudio)
    }
    
    func didBecomeActive() {
        
        if state == .playing && player?.isPlaying == false {
            state = .pause
        }
    }
}


// MARK: Timer

extension AudioPlayer {
    
    func startUpdatePlayingTimeTimer() {
        
        stopUpdatePlayingTimeTimer()
        
        lastListenedDate = nil
        listenTime = 0
        
        updatePlayingTime()
        updatePlayingTimeTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updatePlayingTime), userInfo: nil, repeats: true)
    }
    
    func stopUpdatePlayingTimeTimer() {
        
        updatePlayingTimeTimer?.invalidate()
        updatePlayingTimeTimer = nil
    }
    
    func updatePlayingTime() {
        
        guard player?.isPlaying == true else {
            return
        }
        
        let now = Date()
        listenTime += lastListenedDate != nil ? now.timeIntervalSince(lastListenedDate!) : 0
        lastListenedDate = now
        
        currentTime = player?.currentTime != nil ? Int(player!.currentTime) : currentTime
        
        if let nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo, nowPlayingInfo[MPMediaItemPropertyArtwork] == nil {
            updateArtworkInNowPlayingInfoCenter()
        }
    }
}


// MARK: MPNowPlayingInfoCenter

extension AudioPlayer {
    
    fileprivate func setupInfoCenter(forAudio audio: Audio?) {
        
        guard audio != nil else {
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo: [String: Any] = [:]
        if let title = audio?.title {
            nowPlayingInfo[MPMediaItemPropertyTitle] = title
        }
        if let unionName = audio?.union?.name {
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = unionName
        }
        if let authorName = audio?.author?.fullName {
            nowPlayingInfo[MPMediaItemPropertyArtist] = authorName
        }
        if let duration = audio?.duration {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = NSNumber(integerLiteral: duration)
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: currentTime)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        updateArtworkInNowPlayingInfoCenter()
        
        setupRemoteCommandCenter()
    }
    
    fileprivate func updateCurrentTimeInNowPlayingInfoCenter() {
        
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        guard let audioTitle = nowPlayingInfo?[MPMediaItemPropertyTitle] as? String, audioTitle == currentAudio?.title else {
            return
        }
        
        nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    fileprivate func updateArtworkInNowPlayingInfoCenter() {
        
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        guard let audioTitle = nowPlayingInfo?[MPMediaItemPropertyTitle] as? String, audioTitle == currentAudio?.title else {
            return
        }
        
        guard nowPlayingInfo?[MPMediaItemPropertyArtwork] == nil else {
            return
        }
        
        guard let imageUrlStr = currentAudio?.union?.image, let url = URL(string: imageUrlStr) else {
            return
        }
        
        SDWebImageManager.shared().imageDownloader?.downloadImage(with: url, options: SDWebImageDownloaderOptions(rawValue: 0), progress: nil, completed: { (image, data, error, finished) in
            
            guard image != nil else {
                return
            }
            
            let nowPlayingTitle = MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyTitle] as? String
            guard nowPlayingTitle == audioTitle else {
                return
            }
            
            var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
            nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image!)
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        })
    }
    
    func setupRemoteCommandCenter() {
        
        MPRemoteCommandCenter.shared().skipForwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget { [unowned self] event in
            
            let interval = Int((event as! MPSkipIntervalCommandEvent).interval)
            self.changePlayingAudioTime(self.currentTime + interval)
            
            return .success
        }
        MPRemoteCommandCenter.shared().skipBackwardCommand.isEnabled = true
        MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget { [unowned self] event in
            
            let interval = Int((event as! MPSkipIntervalCommandEvent).interval)
            self.changePlayingAudioTime(self.currentTime - interval)
            
            return .success
        }
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.addTarget { [unowned self] event in
            
            self.play()
            
            return .success
        }
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { [unowned self] event in
            
            self.pause()
            
            return .success
        }
    }
}


// MARK: Remote Control Event

extension AudioPlayer {
    
    func remoteControlReceivedWithEvent(_ event: UIEvent?) {
        
        guard let remoteSubtype = event?.subtype, event?.type == UIEventType.remoteControl else {
            return
        }
        
        switch remoteSubtype {
            
        case .remoteControlTogglePlayPause:
            togglePlayPause()
            
        case .remoteControlPlay:
            play()
            
        case .remoteControlPause:
            pause()
            
        case .remoteControlStop:
            pause()
            
        case .remoteControlNextTrack:
            playNextAudioInUnion()
            
        case .remoteControlBeginSeekingForward:
            break
            
        case .remoteControlEndSeekingForward:
            break
            
        case .remoteControlBeginSeekingBackward:
            break
            
        case .remoteControlEndSeekingBackward:
            break
            
        case .none:
            break
            
        case .motionShake:
            break
            
        case .remoteControlPreviousTrack:
            break
            
        }
    }
}
