//
//  TKSmartCard+DriverLicense.swift
//  DriverLicenseApp
//
//  Created by Watanabe Toshinori on 5/22/19.
//  Copyright © 2019 Watanabe Toshinori. All rights reserved.
//

import Cocoa
import CryptoTokenKit

enum TKDriverCardError: Error, LocalizedError {
    case invalidData(Data)
    
    var errorDescription: String? {
        switch self {
        case .invalidData(let data):
            let hexString = data.map { String(format: "%02X", $0) }.joined()
            return "Invalid Data: \(hexString)"
        }
    }
    
}

extension TKSmartCard {
    
    // MARK: - 運転免許証
    
    /**
        共通データ要素を取得します
     */
    func getCardIssuerData() throws -> Data {
        try selectMF()
        // Select EF01
        try selectEF([0x2F, 0x01])
        let data = try readBinary()
        return data
    }
    
    /**
        記載事項 (本籍除く) を取得します
     
        - parameters:
            - pin1: PIN1
            - pin2: PIN2
     */
    func getBasicData(pin1: String, pin2: String) throws -> Data {
        try selectMF()
        // Verify PIN1
        try selectEF([0x00, 0x01])
        try verify(pin: pin1)
        // Verify PIN2
        try selectEF([0x00, 0x02])
        try verify(pin: pin2)
        // Select DF01
        try selectDF([0xA0, 0x00, 0x00, 0x02, 0x31, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        // Select EF01
        try selectEF([0x00, 0x01])
        
        let data = try readBinary(length: 880)
        return data
    }
    
    /**
         記載事項 (本籍) を取得します
     
         - parameters:
             - pin1: PIN1
             - pin2: PIN2
     */
    func getRegisteredDomicile(pin1: String, pin2: String) throws -> Data {
        try selectMF()
        // Verify PIN1
        try selectEF([0x00, 0x01])
        try verify(pin: pin1)
        // Verify PIN2
        try selectEF([0x00, 0x02])
        try verify(pin: pin2)
        // Select DF01
        try selectDF([0xA0, 0x00, 0x00, 0x02, 0x31, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        // Select EF02
        try selectEF([0x00, 0x02])
        
        let data = try readBinary(length: 82)
        return data
    }
    
    /**
        記載事項変更等 (本籍除く) を取得します
     
         - parameters:
             - pin1: PIN1
             - pin2: PIN2
     */
    func getBasicDataHistory(pin1: String, pin2: String) throws -> Data {
        try selectMF()
        // Verify PIN1
        try selectEF([0x00, 0x01])
        try verify(pin: pin1)
        // Verify PIN2
        try selectEF([0x00, 0x02])
        try verify(pin: pin2)
        // Select DF01
        try selectDF([0xA0, 0x00, 0x00, 0x02, 0x31, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        // Select EF04
        try selectEF([0x00, 0x04])

        let data = try readBinary(length: 640)
        return data
    }
    
    /**
        記載事項変更 (本籍) を取得します
     
         - parameters:
             - pin1: PIN1
             - pin2: PIN2
     */
    func getRegisteredDomicileHistory(pin1: String, pin2: String) throws -> Data {
        try selectMF()
        // Verify PIN1
        try selectEF([0x00, 0x01])
        try verify(pin: pin1)
        // Verify PIN2
        try selectEF([0x00, 0x02])
        try verify(pin: pin2)
        // Select DF01
        try selectDF([0xA0, 0x00, 0x00, 0x02, 0x31, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        // Select EF06
        try selectEF([0x00, 0x06])
        
        let data = try readBinary(length: 256)
        return data
    }

    /**
        写真を取得します
     
         - parameters:
             - pin1: PIN1
             - pin2: PIN2
     */
    func getPhoto(pin1: String, pin2: String) throws -> NSImage {
        try selectMF()
        // Verify PIN1
        try selectEF([0x00, 0x01])
        try verify(pin: pin1)
        // Verify PIN2
        try selectEF([0x00, 0x02])
        try verify(pin: pin2)
        // Select DF02
        try selectDF([0xA0, 0x00, 0x00, 0x02, 0x31, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        // Select EF01
        try selectEF([0x00, 0x01])
        let lengthData = try readBinary(length: 7)
        let length = ASN1LengthParser.parse(data: lengthData)
        let data = try readBinary(length: Int(length))
        
        let record = TKBERTLVRecord.sequenceOfRecords(from: data)
        guard let photoData = record?.first?.value,
            let photo = NSImage(data: photoData) else {
                throw TKDriverCardError.invalidData(data)
        }
        
        return photo
    }

}
