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
import CoreMedia
import AVFoundation
import PGMCameraKit

class ViewController: UIViewController {
    
    
    // MARK: Members
    
    let cameraManager       = PGMCameraKit()
    let helper              = PGMCameraKitHelper()
    var player: AVPlayer!
    
    
    // MARK: @IBOutlets
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var flashModeButton: UIButton!
    @IBOutlet weak var interfaceView: UIView!
    
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let currentCameraState = cameraManager.currentCameraStatus()
        
        if currentCameraState == .NotDetermined || currentCameraState == .AccessDenied {
            
            print("We don't have permission to use the camera.")
            
            cameraManager.askUserForCameraPermissions(completition: { [unowned self] permissionGranted in
                
                if permissionGranted {
                    self.addCameraToView()
                }
                else {
                    self.addCameraAccessDeniedPopup(message: "Go to settings and grant access to the camera device to use it.")
                }
            })
        }
        else if (currentCameraState == .Ready) {
            
            addCameraToView()
        }
        
        if !cameraManager.hasFlash {
            
            flashModeButton.isEnabled = false
            flashModeButton.setTitle("No flash", for: UIControlState.normal)
        }
        
        
        // Limits
        
        cameraManager.maxRecordedDuration = 4.0
        
        
        // Listeners
        
        cameraManager.addCameraErrorListener( cameraError: { [unowned self] error in
            
            if let err = error {
                
                if err.code == CameraError.CameraAccessDeniend.rawValue {
                    
                    self.addCameraAccessDeniedPopup(message: err.localizedFailureReason!)
                }
            }
        })
        
        cameraManager.addCameraTimeListener( cameraTime: { time in
            
            print("Time elapsed: \(String(describing: time)) sec")
        })
        
        cameraManager.addMaxAllowedLengthListener(cameraMaxAllowedLength: { [unowned self] (videoURL, error, localIdentifier) -> () in
            
            if let err = error {
                print("Error \(err)")
            }
            else {
                
                if let url = videoURL {
                    
                    print("Saved video from local url \(url) with uuid \(String(describing: localIdentifier))")
                    
                    let data = NSData(contentsOf: url as URL)!
                    
                    print("Byte Size Before Compression: \(data.length / 1024) KB")
                    
                    // The compress file extension will depend on the output file type
                    self.helper.compressVideo(inputURL: url, outputURL: self.cameraManager.tempCompressFilePath(ext: "mp4"), outputFileType: AVFileTypeMPEG4, handler: { session in
                        
                        if let currSession = session {
                            
                            print("Progress: \(currSession.progress)")
                            
                            print("Save to \(String(describing: currSession.outputURL))")
                            
                            if currSession.status == .completed {
                                
                                if let data = NSData(contentsOf: currSession.outputURL!) {
                                    
                                    print("File size after compression: \(data.length / 1024) KB")
                                    
                                    // Play compressed video
                                    DispatchQueue.main.async(execute: {
                                        
                                        let player  = AVPlayer(url: currSession.outputURL!)
                                        let layer   = AVPlayerLayer(player: player)
                                        layer.frame = self.view.bounds
                                        self.view.layer.addSublayer(layer)
                                        player.play()
                                        
                                        print("Playing video...")
                                    })
                                   
                                }
                            }
                            else if currSession.status == .failed
                            {
                                print(" There was a problem compressing the video maybe you can try again later. Error: \(currSession.error!.localizedDescription)")
                            }
                        }
                    })
                }
            }
            
            // Recording stopped automatically after reached max allowed duration
            self.cameraButton.isSelected = !(self.cameraButton.isSelected)
            self.cameraButton.setTitle(" ", for: UIControlState.selected)
            self.cameraButton.backgroundColor = self.cameraButton.isSelected ? UIColor.red   : UIColor.green
        })
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.isHidden = true
        cameraManager.resumeCaptureSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        cameraManager.stopCaptureSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    
    // MARK: Error Popups
    
    private func addCameraAccessDeniedPopup(message: String) {
        
        DispatchQueue.main.async {
            
        
            self.showAlert(title: "TubeAlert", message: message, ok: "Ok", cancel: "", cancelAction: nil, okAction: { alert in
                
                switch UIDevice.current.systemVersion.compare("8.0.0", options: NSString.CompareOptions.numeric) {
                case .orderedSame, .orderedDescending:
                    UIApplication.shared.openURL(NSURL(string: UIApplicationOpenSettingsURLString)! as URL)
                case .orderedAscending:
                    print("Not supported")
                    break
                }
                }, completion: nil)
        }
    }
    
    
    // MARK: Orientation
    
   
    override var shouldAutorotate: Bool {
        return true
    }
    
    
    
    
    // MARK: Add / Revemo camera
    
    private func addCameraToView()
    {
        _ = cameraManager.addPreviewLayerToView(view: cameraView, newCameraOutputMode: CameraOutputMode.VideoWithMic)
    }
    
    
    // MARK: @IBActions
    
    @IBAction func changeFlashMode(_ sender: UIButton)
    {
        switch (cameraManager.changeFlashMode()) {
        case .Off:
            sender.setTitle("Flash Off", for: UIControlState.normal)
        case .On:
            sender.setTitle("Flash On", for: UIControlState.normal)
        case .Auto:
            sender.setTitle("Flash Auto", for: UIControlState.normal)
        }
    }
    
    @IBAction func recordButtonTapped(_ sender: UIButton) {
        
        switch (cameraManager.cameraOutputMode) {
            
        case .StillImage:
            cameraManager.capturePictureWithCompletition( imageCompletition: { (image, error, localIdentifier) -> () in
                
                if let err = error {
                    print("Error ocurred: \(err)")
                }
                else {
                    print("Image saved to library to id: \(localIdentifier)")
                }
                
                }, name: "ImageName")
            
        case .VideoWithMic, .VideoOnly:
            
            sender.isSelected = !sender.isSelected
            sender.setTitle(" ", for: UIControlState.selected)
            sender.backgroundColor = sender.isSelected ? UIColor.red : UIColor.green
            
            if sender.isSelected {
                
                if cameraManager.timer?.state == .TimerStatePaused {
                    
                    cameraManager.resumeRecordingVideo()
                }
                else {
                    
                    cameraManager.startRecordingVideo( completion: {(error)->() in
                        
                        if let err = error {
                            print("Error ocurred: \(err)")
                        }
                        
                    })
                }
            }
            else {
                
                cameraManager.pauseRecordingVideo()
                
                /*
                cameraManager.stopRecordingVideo( { (videoURL, error, localIdentifier) -> () in
                
                if let err = error {
                print("Error ocurred: \(err)")
                }
                else {
                print("Video url: \(videoURL) with unique id \(localIdentifier)")
                }
                
                })
                */
            }
        }
    }
    
    @IBAction func outputModeButtonTapped(_ sender: UIButton) {
        
        cameraButton.isSelected = false
        cameraButton.backgroundColor = UIColor.green
        
        switch (cameraManager.cameraOutputMode) {
        case .VideoOnly:
            cameraManager.cameraOutputMode = CameraOutputMode.StillImage
            sender.setTitle("Photo", for: UIControlState.normal)
        case .VideoWithMic:
            cameraManager.cameraOutputMode = CameraOutputMode.VideoOnly
            sender.setTitle("Video", for: UIControlState.normal)
        case .StillImage:
            cameraManager.cameraOutputMode = CameraOutputMode.VideoWithMic
            sender.setTitle("Mic On", for: UIControlState.normal)
        }
    }
    
    @IBAction func changeCameraDevice(_ sender: UIButton) {
        
        cameraManager.cameraDevice = cameraManager.cameraDevice == CameraDevice.Front ? CameraDevice.Back : CameraDevice.Front
        switch (cameraManager.cameraDevice) {
        case .Front:
            sender.setTitle("Front", for: UIControlState.normal)
        case .Back:
            sender.setTitle("Back", for: UIControlState.normal)
        }
    }
    
    @IBAction func changeCameraQuality(_ sender: UIButton) {
        
        switch (cameraManager.changeQualityMode()) {
        case .High:
            sender.setTitle("High", for: UIControlState.normal)
        case .Low:
            sender.setTitle("Low", for: UIControlState.normal)
        case .Medium:
            sender.setTitle("Medium", for: UIControlState.normal)
        }
    }
}
