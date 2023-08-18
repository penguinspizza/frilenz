//
//  ViewController.swift
//  Fri+Lenz
//
//  Created by 後藤翔哉 on 2023/08/17.
//

import UIKit
import CommonCrypto
import CoreBluetooth
import Kanna

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate , BLEManagerDelegate
{
//    @IBOutlet weak var TableLbl: UILabel!
    @IBOutlet weak var TableView: UITableView!
    var lalabel:[UILabel] = []
    var members:[String] = []
    var names:[String] = []
    var walltIDs:[String] = []
    var mailAdresses:[String] = []
    var selectedRow:Int?
    var selectedName:String?
    var bleArray = [String]()
    // hashに変換したい値を格納
    var hash1ID:[String] = []
    var userDefaults = UserDefaults.standard

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // BLEManagerをぶち込む
        let bleManager = BLEManager.shared
        bleManager.delegate = self
        BLEManager.shared.delegate = self
    }
    
    // データを送る
    @IBAction func SendDataBtn(_ sender: Any)
    {
        if names.count != 3
        {
            let alert = UIAlertController(title: "2名分以上入力してください", message: "※今回は3名分入力してください", preferredStyle: .alert)
            //ここから追加
            let ok = UIAlertAction(title: "閉じる", style: .default) { (action) in
                self.dismiss(animated: true, completion: nil)
            }
            alert.addAction(ok)
            //ここまで追加
            present(alert, animated: true, completion: nil)
        }
        else
        {
            let alert = UIAlertController(title: "グループを確定しますか？", message: "※グループを一度登録する変更できません", preferredStyle: .alert)
            let ok = UIAlertAction(title: "確定", style: .default) { (action) in
                //移動処理を描く
                self.dismiss(animated: true, completion: nil)
                self.SendOK()
            }
            //ここから追加
            let cancel = UIAlertAction(title: "戻る", style: .cancel) { (acrion) in
                self.dismiss(animated: true, completion: nil)
            }
            alert.addAction(cancel)
            //ここまで追加
            alert.addAction(ok)
            present(alert, animated: true, completion: nil)
        }
    }
    
    // メンバー追加ボタン
    @IBAction func AddMemberBtn(_ sender: Any)
    {
        self.names.append("")
        
        self.TableView.reloadData()
    }
    
    
}

extension ViewController
{
    // MARK: - キーボード以外の場所を触ると、キーボードが閉じられる
    func setDismissKeyboard()
    {
        let tapGR: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGR.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGR)
    }
        
    @objc func dismissKeyboard()
    {
        self.view.endEditing(true)
    }
    
    // MARK: - TableViewの部分始まり
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.names.count
    }
    
    // セルの大きさ
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "Table-Cell"
        
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        
        if (cell == nil)
        {
            cell = UITableViewCell(style: .default, reuseIdentifier: identifier)
        }
        
        cell?.textLabel?.text = self.names[indexPath.row]
        
        return cell!
    }
    
    // スライドでtablecellを消すやつ
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath)
    {
        if (self.names.count <= 1)
        {
            print("消せないよ")
            self.TableView.reloadData()
        }
        else
        {
            self.names.removeLast()
            self.walltIDs.removeLast()
            self.mailAdresses.removeLast()
        }
        self.TableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        self.selectedName = self.names[indexPath.row]
        self.performSegue(withIdentifier: "toTextFields", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
//        let TFVController = segue.destination as? TextFieldsViewController
//        TFVController?.isMembers = self.selectedName
        if let TFVController = segue.destination as? TextFieldsViewController
        {
            TFVController.delegate = self
            TFVController.isMembers = self.selectedName
        }
    }
    
    func SendOK()
    {
        let bleManager = BLEManager.shared
        
        // デバイスの検索
        for i in 0 ..< bleManager.foundPeripherals.count
        {
            if let name = bleManager.foundPeripherals[i].name
            {
                print("コンマ文字列/ (strData)")
                self.bleArray.append(name)
                // 特定のデバイス名を見つけたらスキャンをストップ
                if name == "Fri+Lenz"
                {
                    print("あったよ")
                    bleManager.centralManager?.stopScan()
                }
                else
                {
                    print("ないよ")
                }
            }
            else
            {
                print("*****名無し******")
                self.bleArray.append("(No Name)")
            }
        }
        print("*****bleの中身******")
        print(self.bleArray)
        
        let DevName = self.bleArray.firstIndex(of: "Fri+Lenz")! // ISHIHARA_M5C
        print("*****どこ******")
        print(DevName)
        print("*****どこ******")
        
        let peripheral = bleManager.foundPeripherals[DevName]
        bleManager.connect(peripheral: peripheral)
        
        self.hash1ID.removeAll()    // 中身をリセット
        self.hash1ID.append("on")  // 送るフラグを先に追加
        
        // 配列の数ぶん、処理を行う
        for i in 0 ..< self.walltIDs.count
        {
            var changeID = EncryptionUtil.convertToSha256(string: self.walltIDs[i]) // hashに変換
            self.hash1ID.append(changeID)   // 配列に格納し直す
        }
        
        self.popUp()
    }
    
    
    func popUp()
    {
        let bleManager = BLEManager.shared
        
        let popUpView = UIView(frame: UIScreen.main.bounds)
        popUpView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
        let popViewWidth:CGFloat = 350
        let popViewHeight:CGFloat = 250

        let inView = UIImageView(frame: CGRect(x:UIScreen.main.bounds.width/2 - popViewWidth/2, y:UIScreen.main.bounds.height/2 - popViewHeight/2, width: popViewWidth, height: popViewHeight))
       
        inView.layer.borderColor = CGColor(red: 97/255, green: 80/255, blue: 86/255, alpha: 0.3)  // 枠線の色  // 枠線の色
        inView.layer.borderWidth = 1.0 // 枠線の太さ
        inView.layer.backgroundColor = CGColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.9)  // 枠線の色

        popUpView.addSubview(inView)

        let inLabel = UILabel(frame: CGRect(x:inView.frame.origin.x, y:inView.frame.origin.y, width: 350, height: 250))
        inLabel.textColor = UIColor(red: 97/255, green: 80/255, blue: 86/255, alpha: 1.0)
        inLabel.textAlignment = .center
        inLabel.text = "デバイスへ\n送っています"
        inLabel.font = UIFont.systemFont(ofSize: 24)
        inLabel.numberOfLines = 2
        popUpView.addSubview(inLabel)

        UIApplication.shared.windows.filter{$0.isKeyWindow}.first?.addSubview(popUpView)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            
            // デバイス側へ送る為にする処理
            let strData = self.hash1ID.joined(separator: ",")
            print("コンマ文字列/" + strData)
            let data:Data = strData.data(using: .utf8)!
            // デバイス側へデータを送る
            self.sendMessage(data)
            
            var UDnames = self.userDefaults.array(forKey: "NAMESKEY") as? [String] ?? []
            UDnames = self.names
            self.userDefaults.set(UDnames, forKey: "NAMESKEY")

            var UDwalltIDs = self.userDefaults.array(forKey: "WALLETIDSKEY") as? [String] ?? []
            UDwalltIDs = self.walltIDs
            self.userDefaults.set(UDwalltIDs, forKey: "WALLETIDSKEY")

            var UDmailAdresses = self.userDefaults.array(forKey: "MAILADRESSKEY") as? [String] ?? []
            UDmailAdresses = self.mailAdresses
            self.userDefaults.set(UDmailAdresses, forKey: "MAILADRESSKEY")
            
            self.performSegue(withIdentifier: "toPopUpView", sender: nil)
        })
    }
    
    // デバイス側へデータを送る関数
    func sendMessage(_ data:Data)
    {
        print("鮮度データ前: \(data)")
        let bleManager = BLEManager.shared
        if let peripheral = bleManager.connectedPeripheral, let writeCharacteristic = bleManager.writeharacteristics
        {
            print("鮮度データ後: \(data)")
            peripheral.writeValue(data, for: writeCharacteristic, type:CBCharacteristicWriteType.withResponse)
        }
    }
}

extension ViewController: TextFieldsViewControllerDelegate
{
    func didEnterData(name: String?, walletID: String?, mailAddress: String?)
    {
        print("こんちわ")
        print(name)
        print(walletID)
        print(mailAddress)
        
        if let strName = name, let strwalletID = walletID, let strAdress = mailAddress
        {
            print(strName)
            print(strwalletID)
            print(strAdress)
            
            self.names.append(strName)
            self.walltIDs.append(strwalletID)
            self.mailAdresses.append(strAdress)
            
            self.names.removeAll(where: { $0 == "" })
            self.walltIDs.removeAll(where: { $0 == "" })
            self.mailAdresses.removeAll(where: { $0 == "" })
            
            print(self.names)
            print(self.walltIDs)
            print(self.mailAdresses)
        }
        
       
        self.TableView.reloadData()
    }
    
    // MARK: - hashに変換するやーつ
    class EncryptionUtil
    {
        
        static func convertToSha256(string: String) -> String {
            
            var result: [CUnsignedChar]
            let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
            
            if let cdata = string.cString(using: String.Encoding.utf8) {
                result = Array(repeating: 0, count: digestLength)
                CC_SHA256(cdata, CC_LONG(cdata.count - 1), &result)
            } else {
                fatalError("SHA256の変換に失敗しました")
            }
            return (0..<digestLength).reduce("") {
                $0 + String(format: "%02hhx", result[$1])
            }
        }
    }
}



