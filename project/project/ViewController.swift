//
//  ViewController.swift
//  project
//
//  Created by Maxim De Geyter on 03/12/2019.
//  Copyright © 2019 Maxim De Geyter. All rights reserved.
//

import UIKit
import AVKit
import Vision
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var identifierLabel: UILabel!
    var previousLabel = ""
    var teller = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        camera()
        self.view.bringSubviewToFront(identifierLabel)
        
    }
    
    func camera() {
        // start up the camera
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        // access camera frame layer
        let dataOutput = AVCaptureVideoDataOutput()
        //monitor frame capture
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    func speak() {
        let utterance = AVSpeechUtterance(string: identifierLabel.text!)
        utterance.voice = AVSpeechSynthesisVoice(language: "nl-BE")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.5
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    func checkLabel() {
        if (previousLabel == identifierLabel.text) {
            print("labels are the same")
        } else {
            previousLabel = identifierLabel.text!
            speak()
        }
    }
    
    //deze functie wordt opgeroepen elke keer als er een frame opgevangen is
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        teller+=1;
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // CoreML model
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else { return }
        
        //request van model
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            
            guard let firstObservation = results.first else { return }
            
            print(firstObservation.identifier, firstObservation.confidence)
            
            DispatchQueue.main.async {
                
                if(self.teller % 24 == 0){
                    self.identifierLabel.text = "\(firstObservation.identifier)";
                    self.checkLabel()
                }
                
            }
        }
        // analyseer de frame
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }


}

