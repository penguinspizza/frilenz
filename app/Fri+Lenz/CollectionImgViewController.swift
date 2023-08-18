//
//  CollectionImgViewController.swift
//  Fri+Lenz
//
//  Created by 後藤翔哉 on 2023/08/18.
//

import UIKit
import SDWebImage
import SwiftUI

/// 遷移元
class CollectionImgViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    var URLArray:[String]?
    var selectedRow:Int?
    @IBOutlet weak var CollectionView: UICollectionView!
    override func viewDidLoad()
    {
        super.viewDidLoad()

//        print("表示画像だよん\(self.URLArray)")
        
        if let aaa = self.URLArray
        {
            self.URLArray = aaa // 格納し直す
        }
        
        print("表示画像だよん\(self.URLArray)")
        self.CollectionView.reloadData()
        
//        self.NoView.makeSecure()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleScreenCapture), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
    
    @objc func handleScreenCapture()
    {
           // スクリーンショットが検知されたときの処理をここに記述
           print("スクリーンショットが検知されました")
    }
}

extension CollectionImgViewController
{
    //セクションの中のセルの数を返す
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        //配列の数分cellを作る
        return self.URLArray?.count ?? 0
    }
    
    //セルに表示する内容を記載する
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        // カスタムのキャッシュ設定を使用して画像をダウンロードし、表示する
        let cache = SDImageCache.shared
        cache.config.maxDiskSize = 100 * 1024 * 1024 // 最大キャッシュサイズを100 MBに設定
        cache.config.maxMemoryCost = 50 * 1024 * 1024 // メモリ中の最大キャッシュコストを50 MBに設定
        
        let identifier = "URLcell"
        //storyboard上のセルを生成　storyboardのIdentifierで付けたものをここで設定する
        let cell:UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        
//        //セル上のTag(1)とつけたimgViewを生成
        let imageView = cell.contentView.viewWithTag(1) as! UIImageView
        
        // 画像のURL
        let imageUrl = URL(string: (self.URLArray?[indexPath.row])!)

        // SDWebImageを使用して画像を非同期でダウンロードし、表示する
       imageView.sd_setImage(with: imageUrl, placeholderImage: nil, options: [.refreshCached], context: [.imageThumbnailPixelSize: CGSize(width: 100, height: 100)])
        
        
////        imageView.sd_setImageWithURL(NSURL(string: (self.URLArray?[indexPath.row])!)! as URL)
//        imageView.sd_setImage(with: NSURL(string: (self.URLArray?[indexPath.row])!)! as URL)
        
//        // 単体で呼び出せたやつ
//        self.showImage(imageView: imageView, url: (self.URLArray?[indexPath.row])!)
//
        return cell
    }
    
    //セルのサイズを指定する処理
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        // 正方形で返すためにwidth,heightを同じにする
        return CGSize(width: 190, height: 190)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        self.selectedRow = indexPath.row
        self.performSegue(withIdentifier: "toImgView", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        let IVController = segue.destination as? ImageViewController
        IVController?.imagURL = self.URLArray?[self.selectedRow!]
    }
    
    // 呼び出すやつ（urlを使えるようにする:SDImgに切り替える？）
    func showImage(imageView: UIImageView, url: String)
    {
        let url = URL(string: url)
        DispatchQueue.main.async
        {
            do
            {
                let data = try Data(contentsOf: url!)
                let image = UIImage(data: data)
                imageView.image = image
            } catch let err {
                print("Error: \(err.localizedDescription)")
            }
        }
        
    }
}

