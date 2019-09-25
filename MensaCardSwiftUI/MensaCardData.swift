//
//  MensaCardData.swift
//  MensaCardSwiftUI
//
//  Created by Opahle, Kolya on 24.09.19.
//  Copyright © 2019 Opahle, Kolya. All rights reserved.
//

import Foundation
import CoreNFC
import Combine
import PromiseKit

final class MensaCardData: NSObject, ObservableObject, NFCTagReaderSessionDelegate {
    let objectWillChange = ObservableObjectPublisher()
    
    var credits : Double = 0.0 {
        willSet {
            self.objectWillChange.send()
        }
    }
    
    func scanCard() {
        let readerSession = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
        readerSession?.alertMessage = "Touch your MensaCard to the top of the Phone."
        readerSession?.begin()
    }
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        if tags.count > 1 {
            session.invalidate(errorMessage: "More than 1 tag was found. Please present only 1 tag.")
            return
        }
        
        guard let firstTag = tags.first else {
            session.invalidate(errorMessage: "Unable to get first tag")
            return
        }
        
        session.connect(to: firstTag) { (error: Error?) in
            if error != nil {
                session.invalidate(errorMessage: "Connection error. Please try again.")
                return
            }
            
            switch firstTag {
            case .miFare(let mensaTag):
                firstly {
                    mensaTag.selectApplication([0x5F, 0x84, 0x15])
                }.then { Void -> Promise<Data> in
                    mensaTag.getValue(1)
                }.done { credits in
                    let totalCredits = UInt32(littleEndian: credits.withUnsafeBytes { $0.load(as: UInt32.self) })
                    self.credits = Double(totalCredits) / 1000
                    session.invalidate()
                }.catch { _ in
                    session.invalidate(errorMessage: "Not a valid MensaTag")
                }
            default:
                session.invalidate(errorMessage: "Not a valid MensaTag")
            }
        }
    }
    
    
}
