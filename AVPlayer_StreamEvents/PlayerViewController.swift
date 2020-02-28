//
//  PlayerViewController.swift
//  AVPlayer_StreamEvents
//
//  Created by Mackode - Bartlomiej Makowski on 03/08/2019.
//  Copyright © 2019 com.castlabs.player.streamevents. All rights reserved.
//

import UIKit
import AVKit
import GCDWebServer
import Alamofire

class PlayerViewController: AVPlayerViewController, AVPlayerViewControllerDelegate, AVAssetResourceLoaderDelegate, AVPlayerItemMetadataCollectorPushDelegate {

    var playerItem: AVPlayerItem!
    var metadataCollector: AVPlayerItemMetadataCollector!
    var server: GCDWebServer!
    var identifier: Int = 0
    let formatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        self.formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        // setup proxy
        let server = GCDWebServer()
        server.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self) { (request, completionBlock) in
            Alamofire.request(String(format: "https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/%@", request.url.lastPathComponent)).response { response in
                let fileName = request.url.lastPathComponent
                var data = response.data!

                if fileName.contains(".m3u8") {
                    data = self.overrideManifest(data)
                }

                let serverResponse = GCDWebServerDataResponse(data: data, contentType: "application/x-mpegURL")
                completionBlock(serverResponse)
            }
        }
        server.start()

        // setup AVPlayer
        let proxiedVideoURLString = "\(server.serverURL?.absoluteString ?? "")level_1.m3u8"
        let videoURL = URL(string: proxiedVideoURLString)
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        let asset = AVURLAsset(url: videoURL!)

        //asset.resourceLoader.setDelegate(self, queue: DispatchQueue(label: "asset.resource.loader"))
        asset.loadValuesAsynchronously(forKeys: ["playable"]) {
            DispatchQueue.main.async {
                self.metadataCollector = AVPlayerItemMetadataCollector()
                self.metadataCollector.setDelegate(self, queue: DispatchQueue.main)
                self.playerItem = AVPlayerItem(asset: asset)
                self.playerItem.add(self.metadataCollector)
                self.player = AVPlayer(playerItem: self.playerItem)
                //self.player?.automaticallyWaitsToMinimizeStalling = false
                self.player?.play()
            }
        }
    }

    // NOTE: -- add evetns
    func overrideManifest(_ manifest: Data) -> Data {
        self.identifier += 1
        var modified = String(data: manifest, encoding: .utf8)
        var lines = modified!.split { $0.isNewline }

        let date = Date(timeIntervalSinceReferenceDate: Date.timeIntervalSinceReferenceDate + 50.0)
        let dataRangeLine = Substring(#"#EXT-X-DATERANGE:ID="\#(self.identifier)",START-DATE="\#(self.formatter.string(from: date))",X-AD-ID="3671232",PLANNED-DURATION=24,SCTE35-OUT=0xFC302100000000000000FFF01005000000BB7FEF7F7E0020F580000000000000532C8ACE"#)
        print("--- insert date", self.formatter.string(from: Date()))
        print("--- insert start date", self.formatter.string(from: date))

        lines.insert(dataRangeLine, at: 6)
        modified = lines.joined(separator: "\n")
        return (modified?.data(using: .utf8))!
    }

    // NOTE: -- read events
    func metadataCollector(_ metadataCollector: AVPlayerItemMetadataCollector, didCollect metadataGroups: [AVDateRangeMetadataGroup], indexesOfNewGroups: IndexSet, indexesOfModifiedGroups: IndexSet) {

        for metaGroup in metadataGroups {
            print("--- group ---")
            print("--- now date", self.formatter.string(from: Date()))
            print("--- start date", metaGroup.startDate)

            for metaItem in metaGroup.items {
                print("--- item ---")
                print("---", metaItem)
                print("--- ---- ---")
            }
        }
    }

}

