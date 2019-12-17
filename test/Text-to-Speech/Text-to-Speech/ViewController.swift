//
//  ViewController.swift
//  Text-to-Speech
//
//  Created by Maxim De Geyter on 27/11/2019.
//  Copyright © 2019 Maxim De Geyter. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var text: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        speak()
        
        
    }
    
    func speak() {
        let utterance = AVSpeechUtterance(string: text.text!)
        utterance.voice = AVSpeechSynthesisVoice(language: "nl-BE")
        utterance.rate = 0.5
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
    
    @IBAction func replay(_ sender: UIButton) {
        speak()
        
    }

}

