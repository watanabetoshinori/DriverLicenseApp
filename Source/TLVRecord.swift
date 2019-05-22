//
//  TLVRecord.swift
//  DriverLicenseApp
//
//  Created by Watanabe Toshinori on 5/22/19.
//  Copyright © 2019 Watanabe Toshinori. All rights reserved.
//

import Cocoa

public class TLVRecord {
    
    var tag: UInt64 = 0
    
    var length: UInt64 = 0
    
    var value: Data?
    
    // MARK: - Create TLVRecord objects from Data
    
    class func records(from data: Data) -> [TLVRecord] {
        var records = [TLVRecord]()
        
        let bytes = [UInt8](data)
        var index = 0
        while index < bytes.count {
            let tag = getTag(data: bytes, index: &index)
            let length = getLength(data: bytes, index: &index)
            let value = Int(length) > 0 ? data.subdata(in: Range(index...(index + Int(length) - 1))) : nil
            
            if tag == UInt16(255) {
                // Reached the RFU range
                break
            }
            
            let record = TLVRecord()
            record.tag = tag
            record.length = length
            record.value = value
            records.append(record)
            
            index += Int(record.length)
        }
        
        return records
    }
    
    // MARK: - Parse data to TLV element
    
    class private func getTag(data: [UInt8], index: inout Int) -> UInt64 {
        let val = data[index]
        index += 1
        return UInt64(val)
    }
    
    class private func getLength(data: [UInt8], index: inout Int) -> UInt64 {
        // get Length
        var val = data[index]
        index += 1
        
        if (val & 0x80) == 0 {
            return UInt64(val)
        } else {
            var lengthData = Data()
            lengthData.append(val)
            
            let numberOfDigits = val & 0x7F
            for _ in 0..<numberOfDigits {
                val = data[index]
                index += 1
                
                lengthData.append(val)
            }
            
            if lengthData.count > 8 {
                return 0
            }
            
            var value: UInt64 = 0
            for (i, b) in lengthData.enumerated() {
                let v = UInt64(b) << UInt64(8 * (lengthData.count - i - 1))
                value += v
            }
            return value
        }
    }
    
}
