//
//  TextFieldsViewController.swift
//  Fri+Lenz
//
//  Created by 後藤翔哉 on 2023/08/18.
//

import UIKit

protocol TextFieldsViewControllerDelegate: AnyObject
{
    func didEnterData(name: String?, walletID: String?, mailAddress: String?)
}

class TextFieldsViewController: UIViewController
{
    weak var delegate: TextFieldsViewControllerDelegate?
    
    @IBOutlet weak var NameTF: UITextField!
    //    @IBOutlet weak var NameTF: UITextField!
    @IBOutlet weak var WalletTF: UITextField!
    @IBOutlet weak var AdressTF: UITextField!
    var isMembers:String?
   
    var name:String?
    var walletID:String?
    var MailAdress:String?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print(self.isMembers)
        // キーボードを消す関数を呼び出す
        setDismissKeyboard()
    }

    // タイプミス（OKBtn）
    @IBAction func OKBtん(_ sender: Any)
    {
        self.name = self.NameTF.text
        self.walletID = self.WalletTF.text
        self.MailAdress = self.AdressTF.text
        
        print("テキストfi\(self.NameTF.text)")
        
        if self.name == "" || self.walletID == "" || self.MailAdress == ""
        {
            let alert = UIAlertController(title: "全項目入力してください", message: "", preferredStyle: .alert)
            //ここから追加
            let ok = UIAlertAction(title: "閉じる", style: .default) { (action) in
            }
            alert.addAction(ok)
            //ここまで追加
            present(alert, animated: true, completion: nil)
        }
        else
        {
            delegate?.didEnterData(name: self.name, walletID: self.walletID, mailAddress: self.MailAdress)
            print("テキスト名前\(self.name)")
            self.dismiss(animated: true, completion: nil)
        }
       
    }
    @IBAction func BackBtn(_ sender: Any)
    {
        self.dismiss(animated: true, completion: nil)
    }
}

extension TextFieldsViewController
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
}
