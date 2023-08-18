//
//  PoPUpViewController.swift
//  Fri+Lenz
//
//  Created by 後藤翔哉 on 2023/08/18.
//

import UIKit
import CoreBluetooth
import Alamofire
import SwiftyJSON
import SDWebImage
import Kanna

class PoPUpViewController: UIViewController, BLEManagerDelegate
{
    var readRFID:String = ""
//    let recURL = "http://192.168.0.218:2222" // HOPTER
//    let recURL = "http://192.168.0.2:2222" // 家
    
    
    
    let recURL = "http://192.168.0.141:2222/" // 先輩（json送信部分）
    let hashURL = "http://192.168.0.141:2222/hash" // 先輩（hash受け取り部分）
    
//    var phpURL = "http://192.168.0.141:2222/study/3rd/web3/server/"
    
    var phpURL = "http://192.168.0.176:1111/study/3rd/web3/server/"
    
    var lockkey = ""
    var testlockkey = "ed968e840d10d2d3"
    var compURL = ""
    
//    let testPhpURL = "http://192.168.0.141:2222/study/3rd/web3/server/fromPy.php/" // test用
    let testPhpURL = "http://192.168.0.176:1111/study/3rd/web3/server/fromPy.php/" // test用
    
    @IBOutlet weak var PopUpImgView: UIImageView!
    @IBOutlet weak var PopUpLbl: UILabel!
    
//    NFTBuyImg
    
    //    let recURL = "http://192.168.0.175:2222" // 師匠
    let bleManager = BLEManager.shared
    var userDefaults = UserDefaults.standard // userDefaultsを使いやすいように
    var timer = Timer()
    var namesArray:[String] = []
    var walltIDsArray:[String] = []
    var mailAdressesArray:[String] = []
    var isOne = true
    
    var BCFlag=""
    
    var receivedData: String = ""
    var URLArray:[String] = []

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // BLEManagerのdelegateを設定
            
        let bleManager = BLEManager.shared
        bleManager.delegate = self
        print("まち")
        self.PopUpLbl.text = "デバイスでRFIDを読み込んでください"
    }
    
    func bleManagerDidUpdateValue(bleManager:BLEManager, characteristic:CBCharacteristic, data:Data)
    {
        print("PUVCで使えたよ！")
        if let changeString = String(data: data, encoding: .utf8) {
            self.receivedData = changeString
        } else {
            print("受信したデータを文字列に変換できませんでした。")
        }
        
        // RFIDの読み込みフラグを
        print("取得できた？\(self.receivedData)")
        if self.receivedData == "ReadOff"
        {
            print("読みこみ完了！PythonへJSONデータを送る")
            // pythonへデータ送信
            sendpython()
        }
        
        // デバイスから書き込み完了のフラグを受け取る
        if self.receivedData == "WriteOff"
        {
            // 照合確認フェーズへ
            print("RFIDへ書き込み完了！")
            collationPython()
        }
        
        // デバイスから書き込み完了のフラグを受け取る
        if self.receivedData == "Check"
        {
            // 照合確認フェーズへ
            print("照合完了！")
            accessURL()
        }
    }
        
    // 諸々テスト用ボタン
    @IBAction func TestSend(_ sender: Any)
    {
//        sendpython()
//        collationPython()
        accessURL()
    }

    // pythonへデータ送信
    func sendpython()
    {
        self.PopUpLbl.text = "キーホルダーの読み込みが完了しました!\nNFTを購入してください"
        self.PopUpImgView.image = UIImage(named: "NFTBuyImg")
        
        print("ぺぇそん")
        // ユーザデフォルトから取得（URL配列）
        self.namesArray =  self.userDefaults.array(forKey: "NAMESKEY")as? [String] ?? []
        self.walltIDsArray =  self.userDefaults.array(forKey: "WALLETIDSKEY")as? [String] ?? []
        self.mailAdressesArray =  self.userDefaults.array(forKey: "MAILADRESSKEY")as? [String] ?? []
        
        let parameters: [String: Any] = [
            "Name": self.namesArray,
            "WAdress": self.walltIDsArray,
            "Mail": self.mailAdressesArray
        ]
        
        print("送ったやつ: \(parameters)")

        AF.request(self.recURL,
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding.default,
                   requestModifier: { $0.timeoutInterval = 6000.0 })
        //,headers: HTTPHeaders(["Content-Type": "application/json"]))
                
        .responseString { response in
                print(response)
                switch response.result {
                case .success(let result):
                    self.BCFlag = result
                    self.toBuyFlag()
                    print("Response: \(result)")
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
            print(self.BCFlag)
        if self.BCFlag == "buy"
        {
            // デバイスへ購入されたフラグを送る
            toBuyFlag()
        }
    }
    
    func toBuyFlag()
    {
        // デバイスへbuyフラグを送る
        let data:Data = self.BCFlag.data(using: .utf8)!
        // デバイス側へデータを送る
        self.sendMessage(data)
    }
    
    // pythonへデータ送信
    func collationPython()
    {
        print("ファイルのhashくだせえ")
        self.PopUpLbl.text = "NFTの購入が完了しました\nキーホルダを読み込んでください"
        
        print("hashぺぇそん")
        let parameters: [String: Any] = [
            "Hash": "Please"
        ]
        
        print("送ったやつ: \(parameters)")

        AF.request(self.hashURL,
                   method: .post,
                   parameters: parameters,
                   encoding: JSONEncoding.default,
                   requestModifier: { $0.timeoutInterval = 6000.0 }) // タイムアウトさせない処理
        .responseString { response in
                print("Response: \(response)")
            
                switch response.result {
                case .success(let result):
                    self.lockkey = result
                    print("hashレス: \(self.lockkey)")

                case .failure(let error):
                    print("Error: \(error)")
                }
            }
    }
    
    // 照合完了したら
    func accessURL()
    {
        print("呼ばれた？")
        
        AF.request(self.testPhpURL,
                   method: .get)
//                   parameters: params)
        .responseJSON { res in
            print("***** res *****")
            print(res)
            print("***** res *****")
            // 抜き出した値の中で値だけ抜き出す
            // optional型だから中身を取り出す
            if let data = res.data
            {
                // JSON(data) swiftyjson
                let URLjson = JSON(data)                                // jsonに直す
                
                print("***** 帰ってきたjson *****")
                print(URLjson)                                    // 配列の数
                print("***** 帰ってきたjson *****")
                
                self.URLArray.removeAll()
                
                // 配列の数ぶん、処理を行う
                for i in 0 ..< URLjson.count                            // 配列の数ぶん
                {
                    if var imgPath = URLjson[i].string                   // 配列を1つずつ抜き出し、文字列型に直す
                    {
                        self.compURL = self.phpURL + self.testlockkey + "/" + imgPath
//                        self.compURL = self.phpURL + self.lockkey + "/" + imgPath
                        self.URLArray.append(self.compURL)                    // 配列に格納し直す
                    }
                }
                
                if (self.URLArray.count != 0)
                {
//                    // 移動
//                    self.performSegue(withIdentifier: "toCIVController", sender: nil)
                    self.popUp()
                }
                else
                {
                    self.PopUpLbl.text = "認証失敗"
                    print("失敗")
                }
                
                print("***** 配列の中身 *****")
                print(self.URLArray)
            }
        }
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
            
            // 移動
            self.performSegue(withIdentifier: "toCIVController", sender: nil)
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCIVController" {
            let CIVcontroller = segue.destination as! CollectionImgViewController
            CIVcontroller.URLArray = self.URLArray
        }
    }
    
    // デバイス側へデータを送る関数
    func sendMessage(_ data:Data)
    {
        let bleManager = BLEManager.shared
        if let peripheral = bleManager.connectedPeripheral, let writeCharacteristic = bleManager.writeharacteristics
        {
            peripheral.writeValue(data, for: writeCharacteristic, type:CBCharacteristicWriteType.withResponse)
        }
    }
}
