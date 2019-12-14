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

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var identifierLabel: UILabel!
    var previousLabel = ""
    var teller = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        camera()
        self.view.bringSubviewToFront(labelView)

    }
    
    //gradient pas toevoegen als de constraints toegevoegd zijn aan subviews
    override func viewDidLayoutSubviews() {
        styling()
    }
    
    func setImage() {
        let img = UIImage(named: identifierLabel.text!)
        image.image = img
    }
    
    func styling() {
        let gradient = CAGradientLayer()
        let filter = CIFilter(name: "CIGaussianBlur")
        let lightBlue = UIColor(red: 136.0/255.0, green: 234.0/255.0, blue: 253.0/255.0, alpha: 0.5)
        let darkBlue = UIColor(red: 105.0/255.0, green: 168.0/255.0, blue: 252.0/255.0, alpha: 0.5)
        
        gradient.cornerRadius = 12
        gradient.frame = labelView.bounds
        gradient.colors = [lightBlue.cgColor, darkBlue.cgColor]
        gradient.backgroundFilters = [filter!]
        
        labelView.layer.insertSublayer(gradient, at: 0)
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
        guard let model = try? VNCoreMLModel(for: ImageClassifier().model) else { return }
        
        //request van model
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            
            guard let firstObservation = results.first else { return }
            
            let word = firstObservation.identifier.split(separator: ",")
            
            print(word[0], firstObservation.confidence)
            
            DispatchQueue.main.async {
                
                if(self.teller % 24 == 0){
                    self.identifierLabel.text = "\(word[0])";
                    self.checkLabel()
                    self.setImage()
                }
                
            }
        }
        // analyseer de frame
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }


}

