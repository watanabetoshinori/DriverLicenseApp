//
//  ViewController.swift
//  DriverLicenseApp
//
//  Created by Watanabe Toshinori on 5/22/19.
//  Copyright © 2019 Watanabe Toshinori. All rights reserved.
//

import Cocoa
import CryptoTokenKit

class ViewController: NSViewController {
    
    @IBOutlet weak var pin1Field: NSTextField!

    @IBOutlet weak var pin2Field: NSTextField!

    @IBOutlet weak var nameLabel: NSTextField!

    @IBOutlet weak var birthDayLabel: NSTextField!

    @IBOutlet weak var issuedDateLabel: NSTextField!

    @IBOutlet weak var expirationDateLabel: NSTextField!

    @IBOutlet weak var licenseNumberLabel: NSTextField!

    @IBOutlet weak var historyView: NSTextView!

    @IBOutlet weak var photoView: NSImageView!
    
    // MARK: - ViewController lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // MARK: - Actions
    
    @IBAction func getData(_ sender: Any) {
        do {
            let (pin1, pin2) = try getPINs()

            let card = try TKSmartCard.connect()
            
            try card.beginSession()
            defer {
                card.endSession()
            }
            
            let basicData = try card.getBasicData(pin1: pin1, pin2: pin2)
            displayBasicData(data: basicData)

            let photo = try card.getPhoto(pin1: pin1, pin2: pin2)
            photoView.image = photo

            let historyData = try card.getBasicDataHistory(pin1: pin1, pin2: pin2)
            displayHistoryData(data: historyData)

        } catch {
            alert(error)
        }
    }
    
    // MARK: - Updating UI
    
    private func displayBasicData(data: Data) {
        
        //
        // 運転免許証及び運転免許証作成システム等仕様書
        //   3 論理ファイル
        //     (2) ファイル構成・内容、基本符号化規則 等
        //       キ. 記載事項(本籍除く)
        //
        
        let records = TLVRecord.records(from: data)
        
        if let nameRecord = records.first(where: { $0.tag == UInt64(0x12) }),
            let name = nameRecord.jisX208Value {
            
            nameLabel.stringValue = name
        }
        
        if let birthDayRecord = records.first(where: { $0.tag == UInt64(0x16) }),
            let birthDay = birthDayRecord.dateValue {

            birthDayLabel.stringValue = birthDay
        }
        
        if let issuedDateRecord = records.first(where: { $0.tag == UInt64(0x18) }),
            let issuedDate = issuedDateRecord.dateValue {
            
            issuedDateLabel.stringValue = issuedDate
        }
        
        if let expirationDateRecord = records.first(where: { $0.tag == UInt64(0x1B) }),
            let expirationDate = expirationDateRecord.dateValue {
            
            expirationDateLabel.stringValue = expirationDate
        }
        
        if let licenseNumberRecord = records.first(where: { $0.tag == UInt64(0x21) }),
            let licenseNumber = licenseNumberRecord.jisX201Value {
            
            licenseNumberLabel.stringValue = licenseNumber
        }
    }
    
    private func displayHistoryData(data: Data) {
        
        //
        // 運転免許証及び運転免許証作成システム等仕様書
        //   3 論理ファイル
        //     (2) ファイル構成・内容、基本符号化規則 等
        //       コ. 記載事項変更等(本籍除く)
        //

        let records = TLVRecord.records(from: data)
        
        var histories = [String]()
        
        for i in 1..<records.count {
            if let history = records[i].historyValue {
                histories.append(history)
            }
        }
        
        historyView.string =  histories.joined(separator: "\n")
    }
    
    // MARK: - Get PIN1 and PIN2
    
    private func getPINs() throws -> (String, String) {
        let pin1 = pin1Field.stringValue
        let pin2 = pin2Field.stringValue
        
        if pin1.isEmpty {
            throw NSError(domain: "DriverLicenseApp", code: 0, userInfo: [NSLocalizedDescriptionKey: "PIN1 を入力してください"])
        }
        if pin1.count != 4 {
            throw NSError(domain: "DriverLicenseApp", code: 0, userInfo: [NSLocalizedDescriptionKey: "PIN1 は4文字入力してください"])
        }
        if pin2.isEmpty {
            throw NSError(domain: "DriverLicenseApp", code: 0, userInfo: [NSLocalizedDescriptionKey: "PIN2 を入力してください"])
        }
        if pin2.count != 4 {
            throw NSError(domain: "DriverLicenseApp", code: 0, userInfo: [NSLocalizedDescriptionKey: "PIN2 は4文字入力してください"])
        }
        
        return (pin1, pin2)
    }

    // MARK: - Show Alert
    
    private func alert(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func alert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

}
