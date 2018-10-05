/*
Copyright (c) 2015 Pablo GM <invanzert@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

import Foundation
import AVFoundation
import AssetsLibrary

@objc class PGMCameraKitWriter : NSObject{
    
    
    // MARK: Members
    
    var fileWriter: AVAssetWriter!
    var videoInput: AVAssetWriterInput!
    var audioInput: AVAssetWriterInput!
    
    
    // MARK: Init / Deinit
    
    internal init(fileUrl:NSURL, height:Int, width:Int, channels:UInt32, samples:Float64) {
        
        guard let writer = try? AVAssetWriter(outputURL: fileUrl as URL, fileType: AVFileTypeQuickTimeMovie) else {
            fatalError("AVAssetWriter error")
        }
        
        fileWriter = writer
        
        // Video
        let videoOutputSettings = [AVVideoCodecKey  : AVVideoCodecH264,
                                   AVVideoWidthKey  : NSNumber(value: Int32(width)),
                                   AVVideoHeightKey : NSNumber(value: Int32(height))] as [String : Any]
        
        guard writer.canApply(outputSettings: videoOutputSettings, forMediaType: AVMediaTypeVideo) else {
            fatalError("Can't apply the Output settings for video media.")
        }
        
        videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoOutputSettings)
        videoInput.expectsMediaDataInRealTime = true
        if width > height {
            videoInput.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
        }

        fileWriter.add(self.videoInput)
        
        // Audio
        let audioOutputSettings = [ AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
                                    AVNumberOfChannelsKey : Int(channels),
                                    AVSampleRateKey : Int(samples),
                                    AVEncoderBitRateKey : Int(64000)
        ]
        
        guard writer.canApply(outputSettings: audioOutputSettings, forMediaType: AVMediaTypeAudio) else {
            fatalError("Can't apply the Output settings for audio media.")
        }
        
        self.audioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioOutputSettings)
        self.audioInput.expectsMediaDataInRealTime = true
        self.fileWriter.add(self.audioInput)
    }
    
    internal init(fileUrl:NSURL, height:Int, width:Int) {
        
        guard let writer = try? AVAssetWriter(outputURL: fileUrl as URL, fileType: AVFileTypeQuickTimeMovie) else {
            fatalError("AVAssetWriter error")
        }
        
        fileWriter = writer
        
        // Video
        let videoOutputSettings = [AVVideoCodecKey  : AVVideoCodecH264,
                                   AVVideoWidthKey  : NSNumber(value: Int32(width)),
                                   AVVideoHeightKey : NSNumber(value: Int32(height))] as [String : Any]
        
        guard writer.canApply(outputSettings: videoOutputSettings, forMediaType: AVMediaTypeVideo) else {
            fatalError("Can't apply the Output settings for video media.")
        }
        
        videoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoOutputSettings)
        videoInput.expectsMediaDataInRealTime = true
        if width > height {
            videoInput.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi / 2))
        }

        
        fileWriter.add(self.videoInput)
    }
    
    deinit {
        
        fileWriter = nil
        videoInput = nil
        audioInput = nil
    }
    
    
    // MARK: Writter
    
    internal func write(sample: CMSampleBuffer, isVideo: Bool){
        
        if CMSampleBufferDataIsReady(sample) {
            
            if self.fileWriter.status == .unknown {
                
                print("Start writing, isVideo = \(isVideo), status = \(self.fileWriter.status.rawValue)")
                
                let startTime = CMSampleBufferGetPresentationTimeStamp(sample)
                self.fileWriter.startWriting()
                self.fileWriter.startSession(atSourceTime: startTime)
            }
            
            if self.fileWriter.status == .failed {
                
                print("Error occured, isVideo = \(isVideo), status = \(self.fileWriter.status.rawValue), \(self.fileWriter.error!.localizedDescription)")
                return
            }
            
            if isVideo {
                
                if self.videoInput.isReadyForMoreMediaData {
                    self.videoInput.append(sample)
                }
            }
            else {
                
                if self.audioInput.isReadyForMoreMediaData {
                    self.audioInput.append(sample)
                }
            }
        }
    }
    
    internal func finish(callback:@escaping ()  -> Void){
        self.fileWriter.finishWriting(completionHandler: callback)
    }
}
