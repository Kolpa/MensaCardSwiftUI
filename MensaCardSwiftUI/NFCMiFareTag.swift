//
//  NFCMiFareTag.swift
//  mensa_card_nfc_reader
//
//  Created by Opahle, Kolya on 30.08.19.
//

import Foundation
import CoreNFC
import PromiseKit


public enum MiFareResponse: UInt8, LocalizedError, CaseIterable {
    case OperationOK = 0x00
    case NoChanges = 0x0C
    case OutOfEEPROMError = 0x0E
    case IllegalCommandCode = 0x1C
    case IntegrityError = 0x1E
    case NoSuchKey = 0x40
    case LengthError = 0x7E
    case PermissionDenied = 0x9D
    case ParameterError = 0x9E
    case ApplicationNotFound = 0xA0
    case ApplIntegrityError = 0xA1
    case AuthenticationError = 0xAE
    case AdditionalFrame = 0xAF
    case BoundaryError = 0xBE
    case PICCIntegrityError = 0xC1
    case CommandAborted = 0xCA
    case PICCDisabledError = 0xCD
    case CountError = 0xCE
    case DuplicateError = 0xDE
    case EEPROMError = 0xEE
    case FileNotFound = 0xF0
    case FileIntegrityError = 0xF1

    case InvalidResponse = 0x99

    var localizedDescription: String {
        switch self {
        case .OperationOK: return "OperationOK"
        case .NoChanges: return "NoChanges"
        case .OutOfEEPROMError: return "OutOfEEPROMError"
        case .IllegalCommandCode: return "IllegalCommandCode"
        case .IntegrityError: return "IntegrityError"
        case .NoSuchKey: return "NoSuchKey"
        case .LengthError: return "LengthError"
        case .PermissionDenied: return "PermissionDenied"
        case .ParameterError: return "ParameterError"
        case .ApplicationNotFound: return "ApplicationNotFound"
        case .ApplIntegrityError: return "ApplIntegrityError"
        case .AuthenticationError: return "AuthenticationError"
        case .AdditionalFrame: return "AdditionalFrame"
        case .BoundaryError: return "BoundaryError"
        case .PICCIntegrityError: return "PiccIntegrityError"
        case .CommandAborted: return "CommandAborted"
        case .PICCDisabledError: return "PiccDisabledError"
        case .CountError: return "CountError"
        case .DuplicateError: return "DuplicateError"
        case .EEPROMError: return "EepromError"
        case .FileNotFound: return "FileNotFound"
        case .FileIntegrityError: return "FileIntegrityError"
        case .InvalidResponse: return "InvalidResponse"
        }
    }
}

@available(iOS 13.0, *)
extension NFCMiFareTag {
    public func sendRequest(_ command: UInt8, _ parameters: [UInt8]) -> Promise<Data> {
        return Promise { seal in
            self.sendMiFareCommand(commandPacket: wrapCommand(command, parameters)) { (cmdResp, err) in
                if let cmdErr = err {
                    seal.reject(cmdErr)
                    return
                }

                guard cmdResp[cmdResp.count - 2] == 0x91 else {
                    seal.reject(MiFareResponse.InvalidResponse)
                    return
                }

                guard let rawStatusFrame = cmdResp.last, let statusFrame = MiFareResponse(rawValue: rawStatusFrame) else {
                    seal.reject(MiFareResponse.InvalidResponse)
                    return
                }

                let allData: Data = cmdResp[0..<cmdResp.count - 2]

                switch statusFrame {
                case .OperationOK:
                    seal.fulfill(allData)
                    return
                default:
                    seal.reject(statusFrame)
                    return
                }
            }
        }
    }

    public func wrapCommand(_ command: UInt8, _ parameters: [UInt8]) -> Data {
        var cmdArr: [UInt8] = [0x90, command, 0x00, 0x00]

        if !parameters.isEmpty {
            cmdArr.append(UInt8(parameters.count))
            cmdArr.append(contentsOf: parameters)
        }

        cmdArr.append(0x00)

        return Data(bytes: cmdArr, count: cmdArr.count)
    }
    
    public func getValue(_ fileID: UInt8) -> Promise<Data> {
        return self.sendRequest(0x6C, [fileID])
    }

    public func selectApplication(_ applicationID: [UInt8]) -> Promise<Void> {
        return self.sendRequest(0x5A, applicationID).asVoid()
    }
}
