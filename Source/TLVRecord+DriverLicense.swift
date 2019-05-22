//
//  TLVRecord+DriverLicense.swift
//  DriverLicenseApp
//
//  Created by Watanabe Toshinori on 5/22/19.
//  Copyright © 2019 Watanabe Toshinori. All rights reserved.
//

import Cocoa

extension TLVRecord {

    /// JISX0201 で表した Value
    var jisX201Value: String? {
        guard let value = value else {
            return nil
        }
        
        return String(data: value, encoding: .ascii)
    }

    /// JISX0208 で表した Value
    var jisX208Value: String? {
        guard let value = value else {
            return nil
        }
        
        return jisX208String(from: value)
    }
    
    /// 免許証固有の履歴形式 (HEX + 元号YYMMDD + JISX0208 + JISX0208) で表した Value
    var historyValue: String? {
        // Remove Hex
        guard let value = value?.dropFirst(),
                let string = jisX208String(from: value) else {
            return nil
        }
        
        let datePart = string[string.index(string.startIndex, offsetBy: 0)..<string.index(string.startIndex, offsetBy: 7)]
        let textPart = string[string.index(string.startIndex, offsetBy: 7)..<string.index(string.endIndex, offsetBy: -5)]
        let securityPart = string[string.index(string.endIndex, offsetBy: -5)..<string.endIndex]

        guard let dateString = japaneseDateString(from: String(datePart)) else {
            return nil
        }

        return dateString + " " + textPart + " " + securityPart
    }

    /// 免許証固有の日付形式 (元号YYMMDD) で表した Value
    var dateValue: String? {
        guard let string = jisX201Value,
            let dateString = japaneseDateString(from: string) else {
            return nil
        }
        
        return dateString
    }
    
    // MARK: - Private function
    
    /**
        外字を代替文字に置き換えます
     */
    private func replaceExternalCharacters(from data: Data) -> Data {
        let bytes = [UInt8](data)
        var replacedBytes = [UInt8]()
        
        var index = 0
        while index < bytes.count {
            let b = bytes[index]
            
            if b == 0xFF,
                index < bytes.count - 1 {
                let next = bytes[index + 1]
                switch next {
                case 0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xFA:
                    replacedBytes.append(0x22)
                    replacedBytes.append(0x28)
                    index += 2
                    continue
                default:
                    break
                }
            }
            
            replacedBytes.append(b)
            
            index += 1
        }
        
        return Data(bytes: replacedBytes, count: replacedBytes.count)
    }
    
    /**
        指定したバイト配列を JIS X 208 文字列に変換します
     */
    private func jisX208String(from data: Data) -> String? {
        let replacedData = replaceExternalCharacters(from: data)
        let escapedBytes = [0x1B, 0x24, 0x42] + [UInt8](replacedData) + [0x1B, 0x28, 0x42]
        let escapedData = Data(bytes: escapedBytes, count: escapedBytes.count)
        return String(data: escapedData, encoding: .iso2022JP)
    }
    
    /**
     指定したバイト配列を免許証固有の日付形式 (元号YYMMDD) に変換します
     */
    private func japaneseDateString(from string: String) -> String? {
        if string.count != 7 {
            return nil
        }

        let era = string[string.index(string.startIndex, offsetBy: 0)..<string.index(string.startIndex, offsetBy: 1)]
        let yy = string[string.index(string.startIndex, offsetBy: 1)..<string.index(string.startIndex, offsetBy: 3)]
        let mm = string[string.index(string.startIndex, offsetBy: 3)..<string.index(string.startIndex, offsetBy: 5)]
        let dd = string[string.index(string.startIndex, offsetBy: 5)..<string.index(string.startIndex, offsetBy: 7)]
        
        let eraName: String = {
            switch era {
            case "1", "１":
                return "明治"
            case "2", "２":
                return "大正"
            case "3", "３":
                return "昭和"
            case "4", "４":
                return "平成"
            case "5", "５":
                return "令和"
            default:
                return "不明"
            }
        }()
        
        return "\(eraName)\(yy)年 \(mm)月 \(dd)日"
    }

}
