//
//  BLEManager.swift
//  Fri+Lenz
//
//  Created by 後藤翔哉 on 2023/08/17.
//

import Foundation
import UIKit
import CoreBluetooth

protocol BLEManagerDelegate: AnyObject
{
    func bleManagerFoundPeripheral(bleManager:BLEManager, peripheral:CBPeripheral)
    func bleManagerDidConnectPeripheral(bleManager:BLEManager)
    func bleManagerDidDisconnectPeripheral(bleManager:BLEManager)
    func bleManagerDidFailToConnectPeripheral(bleManager:BLEManager)
    
    func bleManagerDidFoundCharacteristics(bleManager:BLEManager, characteristics:[CBCharacteristic])
    func bleManagerDidUpdateValue(bleManager:BLEManager, characteristic:CBCharacteristic, data:Data) // 受信部分
    
//    func bleManagerDidUpdateValue(bleManager: BLEManager, receivedData: String)
}

extension BLEManagerDelegate
{
    func bleManagerFoundPeripheral(bleManager:BLEManager, peripheral:CBPeripheral) {}
    func bleManagerDidConnectPeripheral(bleManager:BLEManager) {}
    func bleManagerDidDisconnectPeripheral(bleManager:BLEManager) {}
    func bleManagerDidFailToConnectPeripheral(bleManager:BLEManager) {}

    func bleManagerDidFoundCharacteristics(bleManager:BLEManager, characteristics:[CBCharacteristic]) {}
    func bleManagerDidUpdateValue(bleManager:BLEManager, characteristic:CBCharacteristic, data:Data) {}
}

class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate
{
    var centralManager:CBCentralManager?
    var foundPeripherals = [CBPeripheral]()
    var foundCharacteristics = [CBCharacteristic]()
    var isConnected = false
    var connectedPeripheral:CBPeripheral?
    var writeharacteristics:CBCharacteristic? = nil
    var characteristic:CBCharacteristic?
    var peripheral:CBPeripheral?
    weak var delegate:BLEManagerDelegate?
    
    var BLEVal01 = ""
    
    var timer = Timer()
    
    static let shared = BLEManager()
    
    private override init()
    {
        super.init()
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func disconnectPeripheral()
    {
        if let peripheral = self.connectedPeripheral
        {
            self.centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
    
    func refreshFoundPeripherals()
    {
        self.foundPeripherals.removeAll()
    }
    
    func connect(peripheral:CBPeripheral)
    {
        self.centralManager?.connect(peripheral, options: nil)
    }
    
    // MARK: - CBCentralManager Delegate Methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        switch central.state
        {
            // BluetoothがONになっているとき...
            case .poweredOn:
                self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
            
            default:
                break
        }
    }
    
    /* -------------------------------------------------------
     * ペリフェラルが見つかったときに呼び出される
    ------------------------------------------------------- */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber)
    {
        print("みっけた")
        
        if let name = peripheral.name
        {
            if (!self.isConnected) // 繋げるの失敗
            {
                print(name)
                print(peripheral.identifier.uuidString)
            }
        }
        
        var exists = false
        for peri in self.foundPeripherals
        {
            if (peri.identifier.uuidString == peripheral.identifier.uuidString)
            {
                exists = true
                print("exists")
            }
        }
        
        if (!exists)
        {
            self.foundPeripherals.append(peripheral)
            self.delegate?.bleManagerFoundPeripheral(bleManager: self, peripheral: peripheral)
        }
        
            
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral)
    {
        print("せっぞく")
        print("「"+peripheral.name!+"」に接続しました")
        self.isConnected = true
        self.connectedPeripheral = peripheral
        self.connectedPeripheral?.delegate = self
        self.delegate?.bleManagerDidConnectPeripheral(bleManager: self)
        
        // サービスを検索する
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?)
    {
        print("接続できませんでした")
        self.delegate?.bleManagerDidFailToConnectPeripheral(bleManager: self)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?)
    {
        print("切断されました")
        self.isConnected = false
//        self.connectedPeripheral = nil
        self.delegate?.bleManagerDidDisconnectPeripheral(bleManager: self)
    }
    
    // MARK: - CBPeripheral Delegate Methods

    
    /* -------------------------------------------------------
    * サービスが見つかったときに呼び出される
    ------------------------------------------------------- */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?)
    {
        print("サービスが見つかりました")
//        print(peripheral.services)
        
        if let services = peripheral.services
        {
            for service in services
            {
                if (service.uuid.uuidString == "4FAFC201-1FB5-459E-8FCC-C5C9C331914B") //"6E400001-B5A3-F393-E0A9-E50E24DCCA9E")//"F6B61AAC-D6FE-535B-C714-644FE9536104")
                {
                    // キャラクタリスティックを検索する
                    peripheral.discoverCharacteristics(nil, for: service)
                    print(service)
                    print("見つかりました")
                }
            }
        }
    }
    // managerの方
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?)
    {
        print("キャラクタリスティックが見つかりました")

        if let characteristics = service.characteristics
        {
            print("キャラクタリスティックは「\(characteristics.count)個」あるYO")
            for characteristic in characteristics
            {
                // 目的のキャラクタリスティックIDを探す
                if (characteristic.uuid.uuidString == "BEB5483E-36E1-4688-B7F5-EA07361B26A8")// RFデバイスから受信する
                {
                    print("デバイスから受信UUID")
                    peripheral.readValue(for: characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
                    self.characteristic = characteristic
                }
                print(characteristic)
                
//                if (characteristic.uuid.uuidString == "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") // WFデバイスへ送信する
//                {
//                    print("デバイスへ送信UUID")
//
//                    self.writeharacteristics = characteristic
//                }
//                print(characteristic)
                
//                // もう一個characteristic.uuid.uuidStringを使う
                if (characteristic.uuid.uuidString == "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") // デバイスへ送信する
                {
                    print("デバイスへ送信UUID")

                    self.writeharacteristics = characteristic
                }
                print(characteristic)
                
                

            }
        }
        self.delegate?.bleManagerDidFoundCharacteristics(bleManager: self, characteristics: self.foundCharacteristics)
    }
    
    // BLE受信部分
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?)
    {
        print("受信？")
        if let value = characteristic.value
        {
            self.delegate?.bleManagerDidUpdateValue(bleManager: self, characteristic: characteristic, data: value)
            if let changeString = String(data: value, encoding: .utf8) {
                // 文字列の変換に成功した場合
                self.BLEVal01 = changeString
                print("取得した値：\(self.BLEVal01)")
            } else {
                // 文字列の変換に失敗した場合
                print("受信したデータを文字列に変換できませんでした。")
            }
        }
    }
}

