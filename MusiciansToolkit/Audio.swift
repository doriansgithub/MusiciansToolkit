//
//  Audio.swift
//  MusiciansToolkit
//
//  Created by Mark Pizzutillo on 11/14/18.
//  Copyright © 2018 Mark Pizzutillo. All rights reserved.
//

import Foundation
import AudioKit

/// Creates the audio object for the tuner and
/// metronome. Mixer object allows both to
/// work independently.

class Audio {
    var tuner : Tuner?
    var metronome : Metronome?
    var mixer : AKMixer?
    var player : AKPlayer? //Audio file player
    var notePlayer : AKPlayer? //Note player
    var noteBooster : AKBooster? //Note booster
    let microphoneInput : AKMicrophone // Microphone
    let noteGain = 2.0
    
    init() {
        microphoneInput = AKMicrophone()!
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.audioRouteChangeListener(notification:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil)
        
        mixer = AKMixer()
        tuner = Tuner(microphoneInput)
        metronome = Metronome()
        player = AKPlayer()
        
        //Boost note levels as the files are quiet
        notePlayer = AKPlayer()
        noteBooster = AKBooster(notePlayer)
        noteBooster?.gain = noteGain
        
        //Connect tuner and metronome nodes
        mixer?.connect(input: noteBooster)
        mixer?.connect(input: tuner?.node)
        mixer?.connect(input: metronome?.node)
        mixer?.connect(input: player)
        
		AKManager.output = mixer
        AKSettings.audioInputEnabled = true
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
            
            if !AKSettings.headPhonesPlugged {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            }
            try AKManager.start()
        } catch {
            print(error)
        }
    }
    
    @objc func audioRouteChangeListener(notification:NSNotification) {
        let audioRouteChangeReason = notification.userInfo![AVAudioSessionRouteChangeReasonKey] as! UInt
        
        switch audioRouteChangeReason {
        case AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue:
            break
            //Headphones plugged in
        case AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue:
            //Headphones removed
            do {
                // Reset back to main speaker
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            } catch {
                print(error)
            }
            
        default:
            break
        }
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
