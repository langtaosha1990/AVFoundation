//
//  ViewController.swift
//  VideoEdit
//
//  Created by Gpf 郭 on 2023/4/14.
//

import UIKit
import AVFoundation
import Foundation
import AssetsLibrary

enum TransitionType {
    case Dissolve//溶解效果
    case Push
}

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        audioMix()
//        videoAndAudioMix()
        videoChangeWithAnimation()
        
        
    }
    
    func playWithURL(url: URL) {
        let playItem = AVPlayerItem(url: url)
        let player = AVPlayer.init(playerItem: playItem)
        let playerLayer = AVPlayerLayer.init(player: player)
        playerLayer.frame = CGRectMake(0, 0, UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        playerLayer.videoGravity = .resizeAspect
        player.rate = 1.5
        self.view.layer.addSublayer(playerLayer)
        player.play()
    }


}

let videoUrl0 = Bundle.main.url(forResource: "01_nebula", withExtension: "mp4")
let videoUrl1 = Bundle.main.url(forResource: "02_blackhole", withExtension: "mp4")
let videoUrl2 = Bundle.main.url(forResource: "03_nebula", withExtension: "mp4")
let videoUrl3 = Bundle.main.url(forResource: "04_quasar", withExtension: "mp4")

let voiceUrl0 = Bundle.main.url(forResource: "John F. Kennedy", withExtension: "m4a")
let voiceUrl1 = Bundle.main.url(forResource: "Ronald Reagan", withExtension: "m4a")

let musicUrl0 = Bundle.main.url(forResource: "02 Keep Going", withExtension: "m4a")
let musicUrl1 = Bundle.main.url(forResource: "01 Star Gazing", withExtension: "m4a")

extension ViewController {
    
    // 视频截取截取
    func trimVideo(url: URL, startTime: Float64, durationTime: Float64) {
        let videoUrl = Bundle.main.url(forResource: "06_kingaskmexunshan", withExtension: "mp4")
        let asset = AVURLAsset(url: videoUrl!)
        let exportSession = AVAssetExportSession.init(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        let outputPath = self.exportURL()
        exportSession?.outputURL = outputPath
        exportSession?.outputFileType = .mp4
        
        let startTime = CMTimeMakeWithSeconds(startTime, preferredTimescale: 600)
        let duration = CMTimeMakeWithSeconds(durationTime, preferredTimescale: 600)
        let range = CMTimeRangeMake(start: startTime, duration: duration)
        exportSession?.timeRange = range
        
        exportSession?.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                if exportSession?.status == .completed {
                    // 进行播放
                    self.playWithURL(url: exportSession!.outputURL!)
                    // 写入相册
                    self.writeExportedVideoToAssetsLibrary(exportSession: exportSession!)
                } else {
                    fatalError("剪切失败")
                }
            }
        })
        
    }
    
    // 音频混合
    func audioMix() {
        
        let composition = AVMutableComposition()
        let videoMutableTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioMutableTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let musicMutableTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            
        var cursorTime:CMTime = CMTime.zero
        let dic = [AVURLAssetPreferPreciseDurationAndTimingKey:"YES"]
        
        let videoAsset = AVURLAsset(url: videoUrl0!, options: dic)
        let keys = ["tracks", "duration", "commonMetadata"]
        videoAsset.loadValuesAsynchronously(forKeys: keys)
        var assetTrack: AVAssetTrack
        
        assetTrack = videoAsset.tracks(withMediaType: .video).first!
        let videoDuration = CMTimeMake(value: 5, timescale: 1)
        let videoTimeRange = CMTimeRangeMake(start: cursorTime, duration: videoDuration)
        
        do {
            try videoMutableTrack?.insertTimeRange(videoTimeRange, of: assetTrack, at: cursorTime)
            cursorTime = CMTimeAdd(cursorTime, videoDuration)
        } catch {
            fatalError("insert video failed")
        }
        
        
        let videoAsset2 = AVURLAsset(url: videoUrl2!, options: dic)
        videoAsset2.loadValuesAsynchronously(forKeys: keys)
        assetTrack = videoAsset2.tracks(withMediaType: .video).first!
        // 截取视频2的时间范围，可以从0开始
        let videoTimeRange2 = CMTimeRangeMake(start: cursorTime, duration: videoDuration)
        do {
            try videoMutableTrack?.insertTimeRange(videoTimeRange2, of: assetTrack, at: cursorTime)
            cursorTime = CMTimeAdd(cursorTime, videoDuration)
        } catch {
            fatalError("insert video failed")
        }
        
        cursorTime = .zero
        let audioDuration = composition.duration
        let audioTimeRange = CMTimeRangeMake(start: .zero, duration: audioDuration)
        let audioAsset = AVURLAsset(url: voiceUrl0!)
        assetTrack = audioAsset.tracks(withMediaType: .audio).first!
        do {
            try audioMutableTrack?.insertTimeRange(audioTimeRange, of: assetTrack, at: cursorTime)
        } catch {
            fatalError("插入音频失败")
        }
        
        let musicDuration = composition.duration
        let musicTimeRange = CMTimeRangeMake(start: .zero, duration: musicDuration)
        let musicAsset = AVURLAsset(url: musicUrl0!)
        assetTrack = musicAsset.tracks(withMediaType: .audio).first!
        do {
            try musicMutableTrack?.insertTimeRange(audioTimeRange, of: assetTrack, at: cursorTime)
        } catch {
            fatalError("插入音乐失败")
        }
        
        
        // 导出
        let exportSession = AVAssetExportSession(asset: composition, presetName: "AVAssetExportPresetHighestQuality")
        exportSession?.outputURL = self.exportURL()
        exportSession?.outputFileType = AVFileType.mp4
        
        exportSession?.exportAsynchronously {
            DispatchQueue.main.async {
                let status = exportSession?.status
                if (status == .completed) {
                    self.playWithURL(url: exportSession!.outputURL!)
                    self.writeExportedVideoToAssetsLibrary(exportSession: exportSession!);
                } else {
                    
                }
            }
        }
        
    }
    
    // 视频、音频混合
    func videoAndAudioMix() {
        let composition = AVMutableComposition()
        let videoMutableTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        var cursorTime:CMTime = CMTime.zero
        let dic = [AVURLAssetPreferPreciseDurationAndTimingKey:"YES"]
        
        let videoAsset = AVURLAsset(url: videoUrl0!, options: dic)
        let keys = ["tracks", "duration", "commonMetadata"]
        videoAsset.loadValuesAsynchronously(forKeys: keys)
        var assetTrack: AVAssetTrack
        
        assetTrack = videoAsset.tracks(withMediaType: .video).first!
        let videoDuration = CMTimeMake(value: 5, timescale: 1)
        let videoTimeRange = CMTimeRangeMake(start: cursorTime, duration: videoDuration)
        
        do {
            try videoMutableTrack?.insertTimeRange(videoTimeRange, of: assetTrack, at: cursorTime)
            cursorTime = CMTimeAdd(cursorTime, videoDuration)
        } catch {
            fatalError("insert video failed")
        }
        
        
        let videoAsset2 = AVURLAsset(url: videoUrl2!, options: dic)
        videoAsset2.loadValuesAsynchronously(forKeys: keys)
        assetTrack = videoAsset2.tracks(withMediaType: .video).first!
        // 截取视频2的时间范围，可以从0开始
        let videoTimeRange2 = CMTimeRangeMake(start: cursorTime, duration: videoDuration)
        do {
            try videoMutableTrack?.insertTimeRange(videoTimeRange2, of: assetTrack, at: cursorTime)
            cursorTime = CMTimeAdd(cursorTime, videoDuration)
        } catch {
            fatalError("insert video failed")
        }
        
        let audioAsset = AVURLAsset(url: voiceUrl0!)
        let musicAsset = AVURLAsset(url: musicUrl0!)
        let timeRange = CMTimeRangeMake(start: .zero, duration: composition.duration)
        let musicTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        do {
            try musicTrack?.insertTimeRange(timeRange, of: musicAsset.tracks(withMediaType: .audio).first!, at: .zero)
        } catch {
            fatalError("插入音乐失败")
        }
        
        do {
            try audioTrack?.insertTimeRange(timeRange, of: audioAsset.tracks(withMediaType: .audio).first!, at: .zero)
        } catch {
            fatalError("插入音乐失败")
        }
        
        
        let audioMix = AVMutableAudioMix()
        
        // 分别设置两条音轨的变化
        let parameters = AVMutableAudioMixInputParameters(track: musicTrack!)
        parameters.setVolumeRamp(fromStartVolume: 0.0, toEndVolume: 0.0, timeRange: CMTimeRangeMake(start: .zero, duration: CMTimeMake(value: 5, timescale: 1)))
        parameters.setVolumeRamp(fromStartVolume: 0.0, toEndVolume: 1.0, timeRange: CMTimeRangeMake(start: CMTimeMake(value: 5, timescale: 1), duration: CMTimeMake(value: 5, timescale: 1)))
        
        let audioParameters = AVMutableAudioMixInputParameters(track: audioTrack!)
        audioParameters.setVolumeRamp(fromStartVolume: 1.0, toEndVolume: 0.0, timeRange: CMTimeRangeMake(start: .zero, duration: CMTimeMake(value: 5, timescale: 1)))
        
        audioMix.inputParameters = [parameters, audioParameters]
        
        // 导出
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.audioMix = audioMix
        exportSession?.outputURL = self.exportURL()
        exportSession?.outputFileType = AVFileType.mp4
        
        exportSession?.exportAsynchronously {
            DispatchQueue.main.async {
                let status = exportSession?.status
                if (status == .completed) {
                    self.playWithURL(url: exportSession!.outputURL!)
                    self.writeExportedVideoToAssetsLibrary(exportSession: exportSession!);
                } else {
                    
                }
            }
        }
        
    }
    
    // 视频转场动画
    func videoChangeWithAnimation() {
        // 创建AVMutableComposition和tracks
        let composition = AVMutableComposition()
        // 在composition中添加两个视频轨道和两个音频轨道
        composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        // 获取composition下的视频轨道
        let videoTracks = composition.tracks(withMediaType: .video)
        
        var cursorTime:CMTime = CMTime.zero
        //转场动画时间
        let transitionDuration = CMTime(value: 2, timescale: 1)
        
        let videos = [AVURLAsset(url: videoUrl0!), AVURLAsset(url: videoUrl1!), AVURLAsset(url: videoUrl2!), AVURLAsset(url: videoUrl3!)]
        
        // 设置截取每个视频的长度
        let duration = CMTime(value: 5, timescale: 1)
        for (index, value) in videos.enumerated() {
            // 交叉循环A、B轨道
            let trackIndex = index % 2
            let currentTrack = videoTracks[trackIndex]
            
            // 获取视频轨道
            guard let assetTrack = value.tracks(withMediaType: .video).first else {
                continue
            }
            
            do {
                // 插入视频片段
                try currentTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: assetTrack, at: cursorTime)
                //光标移动到视频末尾处，以便插入下一段视频
                cursorTime = CMTimeAdd(cursorTime, duration)
                //光标回退转场动画时长的距离，这一段前后视频重叠部分组合成转场动画
                cursorTime = CMTimeSubtract(cursorTime, transitionDuration)
            } catch {
                fatalError("")
            }
        }
        
        // 通过AVVideoComposition设置视频转场动画相关
        let videoComposition = AVMutableVideoComposition.init(propertiesOf: composition)
        // 获取composition下重叠的过度片段
        let instructions = videoComposition.instructions as! [AVMutableVideoCompositionInstruction]
        
        
        var a = 0 // 设置变量参数控制视频转场动画
        for (index, instruct) in instructions.enumerated() {
            guard instruct.layerInstructions.count > 1 else {
                continue
            }
            //需要判断转场动画是从A轨道到B轨道，还是B-A
            var fromLayer: AVMutableVideoCompositionLayerInstruction
            var toLayer: AVMutableVideoCompositionLayerInstruction
            //获取前一段画面的轨道id
            let beforeTrackId = instructions[index - 1].layerInstructions[0].trackID;
            //跟前一段画面同一轨道的为转场起点，另一轨道为终点
            let tempTrackId = instruct.layerInstructions[0].trackID
            // 按照顺序获取前后视频id
            if beforeTrackId == tempTrackId {
                fromLayer = instruct.layerInstructions[0] as! AVMutableVideoCompositionLayerInstruction
                toLayer = instruct.layerInstructions[1] as! AVMutableVideoCompositionLayerInstruction
            }else{
                fromLayer = instruct.layerInstructions[1] as! AVMutableVideoCompositionLayerInstruction
                toLayer = instruct.layerInstructions[0] as! AVMutableVideoCompositionLayerInstruction
            }
            
            let identityTransform = CGAffineTransform.identity
            let timeRange = instruct.timeRange
            let videoWidth = videoComposition.renderSize.width
            let videoHeight = videoComposition.renderSize.height
            
            // 推入动画
            if a == 0 {
                let formEndTransform = CGAffineTransform(translationX: -videoWidth, y: 0)
                let toStartTransform = CGAffineTransform(translationX: videoWidth, y: 0)
                
                fromLayer.setTransformRamp(fromStart: identityTransform, toEnd: formEndTransform, timeRange: timeRange)
                toLayer.setTransformRamp(fromStart: toStartTransform, toEnd: identityTransform, timeRange: timeRange)
                a += 1
            } else if a == 1 {
                // 溶解动画
                fromLayer.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 0.0, timeRange: timeRange)
                toLayer.setOpacityRamp(fromStartOpacity: 0.0, toEndOpacity: 1.0, timeRange: timeRange)
                a += 1
            } else if a == 2 {
                // 擦除动画
                let startRect = CGRectMake(0.0, 0.0, videoWidth, videoHeight)
                let endRect = CGRectMake(videoWidth, videoHeight, videoWidth, videoHeight)
                fromLayer.setCropRectangleRamp(fromStartCropRectangle: startRect, toEndCropRectangle: endRect, timeRange: timeRange)
                a += 1
            }
            instruct.layerInstructions = [fromLayer, toLayer]
        }
        
        let audioTracks = composition.tracks(withMediaType: .audio)
        
        
        let musicAsset = AVURLAsset(url: musicUrl0!)
        let audioAsset = AVURLAsset(url: voiceUrl0!)
        let musicTrack = audioTracks[0]
        let audioTrack = audioTracks[1]
        // 根据视频时长初始化整个音频的时长
        let timeRange = CMTimeRangeMake(start: .zero, duration: composition.duration)
        // 初始混合语音的时长
        let audioRange = CMTimeRange(start: CMTime(value: 2, timescale: 1), duration: CMTime(value: 4, timescale: 1))
        
        do {
            // 插入背景音乐
            try musicTrack.insertTimeRange(timeRange, of: musicAsset.tracks(withMediaType: .audio).first!, at: .zero)
        } catch {
            fatalError("插入音频失败")
        }
        do {
            // 插入语音
            try audioTrack.insertTimeRange(audioRange, of: audioAsset.tracks(withMediaType: .audio).first!, at: CMTime(value: 2, timescale: 1))
        } catch {
            fatalError("插入音频失败")
        }
        // 创建AVMutableAudioMix对象用来混合背景音乐和语音
        let audioMix = AVMutableAudioMix()
        // 分别设置两条音轨的变化，这里设置1~2秒背景音乐逐渐降低，3~5秒音频渐起渐落，5~最后背景音乐
        // 背景音乐的设置
        let parameters = AVMutableAudioMixInputParameters(track: musicTrack)
        // 1~2S降低
        parameters.setVolumeRamp(fromStartVolume: 1.0, toEndVolume: 0.0, timeRange: CMTimeRangeMake(start: .zero, duration: CMTimeMake(value: 2, timescale: 1)))
        // 5S升高
        parameters.setVolumeRamp(fromStartVolume: 0.0, toEndVolume: 1.0, timeRange: CMTimeRangeMake(start: CMTimeMake(value: 5, timescale: 1), duration: CMTimeMake(value: 5, timescale: 1)))
        
        // 语音的设置
        let audioParameters = AVMutableAudioMixInputParameters(track: audioTrack)
        audioParameters.setVolumeRamp(fromStartVolume: 0.0, toEndVolume: 1.0, timeRange: CMTimeRangeMake(start: CMTime(value: 2, timescale: 1), duration: CMTimeMake(value: 1, timescale: 2)))
        audioParameters.setVolumeRamp(fromStartVolume: 1.0, toEndVolume: 0.0, timeRange: CMTimeRangeMake(start: CMTime(value: 4, timescale: 1), duration: CMTimeMake(value: 1, timescale: 1)))
        
        audioMix.inputParameters = [parameters, audioParameters]
        
        // 导出
        let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exportSession?.audioMix = audioMix
        exportSession?.outputURL = self.exportURL()
        exportSession?.outputFileType = AVFileType.mp4
        exportSession?.videoComposition = videoComposition
        exportSession?.exportAsynchronously {
            DispatchQueue.main.async {
                let status = exportSession?.status
                if (status == .completed) {
                    self.playWithURL(url: exportSession!.outputURL!)
                    self.writeExportedVideoToAssetsLibrary(exportSession: exportSession!);
                } else {
                    
                }
            }
        }
        
    }

    
    func writeExportedVideoToAssetsLibrary(exportSession: AVAssetExportSession) {
        let url = exportSession.outputURL
        let library = ALAssetsLibrary()
        if library.videoAtPathIs(compatibleWithSavedPhotosAlbum: url!) {
            library.writeVideoAtPath(toSavedPhotosAlbum: url!, completionBlock: {
                assetURL, error in
                if error != nil {
                    fatalError("写入相册失败")
                } else {
                    print("写入相册成功")
                }
                do {
                    try FileManager.default.removeItem(at: url!)
                } catch {
                    fatalError("文件删除失败:\(url!)")
                }
                
            })
        }
    }
    
    func exportURL() -> URL {
        var filePath:String
        var count: Int = 0
        repeat {
            filePath = NSTemporaryDirectory()
            let numberString = count > 0 ? String(count):""
            let fileNameString = "Masterpiece-" + numberString + ".mp4"
            filePath = filePath.appending(fileNameString)
            count += 1;
        }while (FileManager.default.fileExists(atPath: filePath))
        return URL(fileURLWithPath: filePath)
    }
    
}

