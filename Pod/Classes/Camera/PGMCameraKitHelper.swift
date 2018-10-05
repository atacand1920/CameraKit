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

import UIKit
import Photos
import Accelerate

public typealias LocalIdentifierType       = String
public typealias LocalIdentifierBlock      = (_ localIdentifier: LocalIdentifierType?, _ error: NSError?) -> ()
public typealias ImageWithIdentifierBlock  = (_ image:UIImage?) -> ()
public typealias VideoWithIdentifierBlock  = (_ video:NSURL?) -> ()
public typealias FrameBuffer               = (inBuffer: vImage_Buffer, outBuffer: vImage_Buffer, pixelBuffer: UnsafeMutableRawPointer)

@objc public class PGMCameraKitHelper: NSObject {

    var manager = PHImageManager.default()
    
    
    // MARK: Save Image
    
    public func saveImageAsAsset(image: UIImage, completion: @escaping LocalIdentifierBlock) {
        
        var imageIdentifier: LocalIdentifierType?
        
        PHPhotoLibrary.shared().performChanges({ () -> () in
            
            let changeRequest   = PHAssetChangeRequest.creationRequestForAsset(from: image)
                
                let placeHolder     = changeRequest.placeholderForCreatedAsset
                
                imageIdentifier = placeHolder?.localIdentifier
            
            },
            completionHandler: { (success, error) -> () in
                if success {
                    completion(imageIdentifier, nil)
                }
                else {
                    completion(nil, error as! NSError)
                }
        })
    }
    
    
    // MARK: Save Video
    
    public func saveVideoAsAsset(videoURL: NSURL, completion: @escaping LocalIdentifierBlock) {
        
        var videoIdentifier: LocalIdentifierType?
        
        PHPhotoLibrary.shared().performChanges({ () -> () in
            
            let changeRequest   = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL as URL)
            
            let placeHolder     = changeRequest?.placeholderForCreatedAsset
            
            videoIdentifier = placeHolder?.localIdentifier
            
            },
            completionHandler: { (success, error) -> () in
                if success {
                    completion(videoIdentifier, nil)
                }
                else {
                    completion(nil, error as NSError?)
                }
        })
    }
    
    
    // MARK: Retrieve Image by Id
    
    public func retrieveImageWithIdentifer(localIdentifier:LocalIdentifierType, completion: @escaping ImageWithIdentifierBlock) {
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: fetchOptions)
        
        if fetchResults.count > 0 {
            
             let imageAsset = fetchResults.object(at: 0)
           
                let requestOptions = PHImageRequestOptions()
                
                requestOptions.deliveryMode = .highQualityFormat
                
            manager.requestImage(for: imageAsset, targetSize: PHImageManagerMaximumSize,
                                 contentMode: .aspectFill, options: requestOptions,
                                             resultHandler: { (image, info) -> () in
                    
                                                completion(image)
                })
            }
        else {
            completion(nil)
        }
    }
    
    
    // MARK: Retrive video by id
    
    public func retrieveVideoWithIdentifier(localIdentifier:LocalIdentifierType, completion: @escaping VideoWithIdentifierBlock) {
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        
        let fetchResults = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: fetchOptions)
        
        if fetchResults.count > 0 {
            
            if let videoAsset = fetchResults.object(at: 0) as? PHAsset {
                
                /* We want to be able to display a video even if it currently
                resides only on the cloud and not on the device */
                let options = PHVideoRequestOptions()
                options.deliveryMode = .automatic
                options.isNetworkAccessAllowed = true
                options.version = .current
                options.progressHandler = {(progress: Double,
                    error: NSError?,
                    stop: UnsafeMutablePointer<ObjCBool>,
                    info: [NSObject : AnyObject]?) in
                    
                    /* You can write your code here that shows a progress bar to the
                    user and then using the progress parameter of this block object, you
                    can update your progress bar. */
                    } as? PHAssetVideoProgressHandler
                
                /* Now get the video */
                PHCachingImageManager().requestAVAsset(forVideo: videoAsset,
                    options: options,
                    resultHandler: {(asset: AVAsset?,
                        audioMix: AVAudioMix?,
                        info: [NSObject : AnyObject]?) in
                        
                        if let asset = asset as? AVURLAsset{
                            completion(asset.url as NSURL)
                        } else {
                            print("This is not a URL asset. Cannot play")
                        }
                        
                        } as! (AVAsset?, AVAudioMix?, [AnyHashable : Any]?) -> Void)
            }
            else {
                completion(nil)
            }
        }
        else {
            completion(nil)
        }
    }
    
    
    // MARK: Compress Video
    
    public func compressVideo(inputURL: NSURL, outputURL: NSURL, outputFileType:String, handler:@escaping (_ session: AVAssetExportSession?)-> Void)
    {
        let urlAsset = AVURLAsset(url: inputURL as URL, options: nil)
        
        let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality)
        
        exportSession?.outputURL = outputURL as URL
        
        exportSession?.outputFileType = outputFileType
        
        exportSession?.shouldOptimizeForNetworkUse = true
        
        exportSession?.exportAsynchronously { () -> Void in
            
            handler(exportSession)
        }
    }
}
