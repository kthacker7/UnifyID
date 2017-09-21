//
//  ViewController.swift
//  UnifyIDInterview
//
//  Created by Kunal Thacker on 9/20/17.
//  Copyright © 2017 Kunal Thacker. All rights reserved.
//

import UIKit
import AVFoundation
import KeychainSwift
import LocalAuthentication

class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    @IBOutlet weak var cameraPreviewView: UIView!
    var session :AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var videoOutput: AVCaptureMovieFileOutput?
    var imageKeys: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        if (AVCaptureDevice.authorizationStatus(for: .video) == AVAuthorizationStatus.authorized) {
            startRecording()
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (status) in
                if (status) {
                    self.startRecording()
                }
            })
        }
    }
    
    func startRecording() {
        if (AVCaptureDevice.authorizationStatus(for: .video) == AVAuthorizationStatus.authorized) {
            if (UIImagePickerController.isCameraDeviceAvailable(UIImagePickerControllerCameraDevice.front)) {
                if let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
                    do {
                        let videoInput = try AVCaptureDeviceInput(device: frontDevice)
                        session = AVCaptureSession()
                        session?.addInput(videoInput)
                        previewLayer = AVCaptureVideoPreviewLayer(session: session!)
                        previewLayer?.frame = self.cameraPreviewView.frame
                        DispatchQueue.main.async {
                            self.cameraPreviewView.layer.addSublayer(self.previewLayer!)
                        }
                        session?.startRunning()
                    }
                    catch {
                        print(error)
                    }
                    
                }
            }
        }
    }
    
    func takeFiveSecondVideo() {
        videoOutput = AVCaptureMovieFileOutput()
        self.session?.addOutput(videoOutput!)
        var filePath : String?
        
        let docDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)
        let path = docDirectory[0] + "/movieURL.mp4"
        if (FileManager.default.fileExists(atPath: path)) {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                print(error)
            }
        }
        filePath = path
        
        if filePath != nil {
            let url = URL(fileURLWithPath: filePath!)
            videoOutput?.startRecording(to: url, recordingDelegate: self)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5 , execute: {
                print("Stopping recoding")
                self.videoOutput?.stopRecording()
            })
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if (error != nil) {
            print(error!)
        } else {
            self.getSnapshotsFromURL(fileURL: outputFileURL)
        }
    }
    
    func getSnapshotsFromURL(fileURL : URL) {
        var snapshots : [UIImage] = []
        var snapshotsData : [Data] = []
        var snapshotPaths : [URL] = []
        let asset = AVURLAsset(url: fileURL)
        let imageGen = AVAssetImageGenerator(asset: asset)
        imageGen.requestedTimeToleranceAfter = kCMTimeZero
        imageGen.requestedTimeToleranceBefore = kCMTimeZero
        imageGen.appliesPreferredTrackTransform = true
        let duration = CMTimeGetSeconds(asset.duration)
        var i = 0.0
        while i < duration * 2 {
            let time = CMTimeMake(Int64(i), 2)
            do {
                if (snapshots.count <= 10) {
                    let cgImage = try imageGen.copyCGImage(at: time, actualTime: nil)
                    let uiImage = UIImage(cgImage: cgImage)
                    snapshots.append(uiImage)
                }
            } catch {
                print(error)
            }
            i = i + 1
        }
        var j = 0
        let docDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true)
        
        
        for img in snapshots {
            var path = docDirectory[0] + "/snapshot"
            if let data = UIImagePNGRepresentation(img) {
                path = path + "\(j).png"
                if (FileManager.default.fileExists(atPath: path)) {
                    do {
                        try FileManager.default.removeItem(atPath: path)
                    } catch {
                        print(error)
                    }
                }
                do {
                    let fileURL = URL(fileURLWithPath: path)
                    try data.write(to: fileURL)
                    snapshotPaths.append(fileURL)
                    snapshotsData.append(data)
                } catch {
                    print(error)
                }
            }
            j = j + 1
        }
        
        if (FileManager.default.fileExists(atPath: fileURL.absoluteString)) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.absoluteString)
            } catch {
                print(error)
            }
        }
        let keychain = KeychainSwift()
        keychain.synchronizable = false
        j = 0
        for data in snapshotsData {
            keychain.set(data, forKey: snapshotPaths[j].absoluteString, withAccess: KeychainSwiftAccessOptions.accessibleWhenUnlockedThisDeviceOnly)
            j = j + 1
        }
        self.imageKeys = []
        for path in snapshotPaths {
            imageKeys.append(path.absoluteString)
        }
        
    }

    @IBAction func takeSnapshot(_ sender: Any) {
        self.takeFiveSecondVideo()
    }
    
    @IBAction func viewSnapshots(_ sender: Any) {
        let context = LAContext()
        if (context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Only you can see the snapshots!", reply: { (success, error) in
                if (error == nil && success) {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    if let vc = storyboard.instantiateViewController(withIdentifier: "ImageCollectionViewController") as? ImageCollectionViewController {
                        vc.imageKeys = self.imageKeys
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                    
                } else {
                    let alert = UIAlertController(title: "OOPS!", message: "Your authentication failed :(", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            })
        } else {
            let alert = UIAlertController(title: "OOPS!", message: "You cannot authenticate this!", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

