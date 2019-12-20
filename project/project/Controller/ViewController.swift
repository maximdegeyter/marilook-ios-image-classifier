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
import SwiftyJSON

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var labelView: UIView!
    @IBOutlet weak var identifierLabel: UILabel!
    @IBOutlet weak var btn: UIButton!
    @IBOutlet weak var questionView: UIView!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var questionImg: UIImageView!
    @IBAction func replaySpeak(_ sender: Any) {
        speak()
    }
    
    
    var previousLabel = ""
    var teller = 0;
    var audioPlayer: AVAudioPlayer?
    var objects:AllObjects?
    let synthesizer = AVSpeechSynthesizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        loadJSON()
        camera()
        questionView.isHidden = true
        btn.addTarget(self, action: #selector(didButtonClick), for: .touchUpInside)
    }
    
    //gradient pas toevoegen als de constraints toegevoegd zijn aan subviews
    override func viewDidAppear(_ animated: Bool) {
        styling()
    }
    
    @objc func didButtonClick(_ sender: UIButton) {
        questionView.isHidden = !questionView.isHidden
        setBtnImg()
        getRandomObj()
    }
    
    func loadJSON() {
        let url = Bundle.main.url(forResource: "objects", withExtension: "json")
        if let path = url{
            do{
                let data = try Data(contentsOf: path);
                let result = try JSON(data: data);
                parseJSON(json: result);
            }catch{
                print("ERROR: JSON DATA CAN NOT BE LOADED.")
            }
        }else{
            print("ERROR: PATH TO JSON NOT CORRECT. ")
        }
    }
    
    func parseJSON(json:JSON){
        var tempList:[Object] = []
        for (_ ,subJSON) in json["objects"] {
            let item:Object = Object(id: subJSON["id"].intValue, word: subJSON["word"].stringValue)
            tempList.append(item)
        }
        objects = AllObjects(list: tempList)
        print(objects!)
    }
    
    func getRandomObj() {
        if questionView.isHidden == false {
            let obj = objects!.list.randomElement()!
            questionLabel.text = obj.word
            let img = UIImage(named: obj.word)
            questionImg.image = img
        }
    }
    
    func setImage() {
        let img = UIImage(named: identifierLabel.text!)
        image.image = img
        image.alpha = 0
        image.transform = CGAffineTransform.identity.scaledBy(x: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: {
                        self.image.alpha = 1
                        self.image.transform = CGAffineTransform.identity.scaledBy(x: 1, y: 1)
                    }, completion: nil)
        
    }
    
    func styling() {
        //let gradient = CAGradientLayer()
        //let filter = CIFilter(name: "CIGaussianBlur")
        //let lightBlue = UIColor(red: 136.0/255.0, green: 234.0/255.0, blue: 253.0/255.0, alpha: 0.5)
        //let darkBlue = UIColor(red: 105.0/255.0, green: 168.0/255.0, blue: 252.0/255.0, alpha: 0.5)
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.labelView.frame
        blurEffectView.clipsToBounds = true
        blurEffectView.layer.cornerRadius = 50
        self.view.insertSubview(blurEffectView, at: 1)
        
        btn.layer.cornerRadius = 24
        btn.clipsToBounds = true
        
        //gradient.frame = labelView.bounds
        //gradient.colors = [lightBlue.cgColor, darkBlue.cgColor]
        //gradient.backgroundFilters = [filter!]
        
        //labelView.layer.insertSublayer(gradient, at: 0)
    }
    
    func setBtnImg() {
        if questionView.isHidden == true {
            let openImg = UIImage(named: "Ogen.png")
            btn.setImage(openImg, for: .normal)
        } else {
            let closeImg = UIImage(named: "Sluit.png")
            btn.setImage(closeImg, for: .normal)
        }
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
        view.layer.insertSublayer(previewLayer, at: 0)
        previewLayer.frame = view.frame
        
        // access camera frame layer
        let dataOutput = AVCaptureVideoDataOutput()
        //monitor frame capture
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    func speak() {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: identifierLabel.text!)
        utterance.voice = AVSpeechSynthesisVoice(language: "nl-BE")
        utterance.rate = 0.5
        utterance.preUtteranceDelay = 0.2
        
        synthesizer.speak(utterance)
    }
    
    func checkLabel() {
        if (previousLabel == identifierLabel.text) {
            print("labels are the same")
        } else {
            previousLabel = identifierLabel.text!
            playSound(sound: "success.wav")
            speak()
            setImage()
            
            if (questionView.isHidden == false) {
                checkAnswer()
            }
        }
    }
    
    func checkAnswer() {
        if (questionLabel.text == identifierLabel.text) {
            print("juist!")
            playSound(sound: "correct.wav")
            questionView.isHidden = true
            setBtnImg()
        } else {
            playSound(sound: "false.wav")
            shake()
            print("fout!")
        }
    }
    
    func playSound(sound: String) {
        let path = Bundle.main.path(forResource: sound, ofType: nil)
        let url = URL(fileURLWithPath: path!)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer!.play()
        } catch {
            print("couldnt load file")
        }
    }
    
    func shake() {
        let ShakeAnimation = CABasicAnimation(keyPath: "position")
        ShakeAnimation.duration = 0.07
        ShakeAnimation.repeatCount = 5
        ShakeAnimation.autoreverses = true
        ShakeAnimation.fromValue = NSValue(cgPoint: CGPoint(x: image.center.x - 10, y: image.center.y))
        ShakeAnimation.toValue = NSValue(cgPoint: CGPoint(x: image.center.x + 10, y: image.center.y))
        image.layer.add(ShakeAnimation, forKey: "position")
    }

    //deze functie wordt opgeroepen elke keer als er een frame opgevangen is
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        teller+=1;
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // CoreML model
        guard let model = try? VNCoreMLModel(for: MyImageClassifier().model) else { return }
        
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
                }
                
            }
        }
        // analyseer de frame
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
}
