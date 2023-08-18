//
//  ImageViewController.swift
//  Fri+Lenz
//
//  Created by 後藤翔哉 on 2023/08/18.
//

import UIKit
import SDWebImage
import SwiftUI

class ImageViewController: UIViewController
{
//    var imageNo:Int?
    var imagURL:String?

    // タイプミス
    
    @IBOutlet weak var ImgView: UIImageView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

//        self.ImgView.image =
        
        // バグるかも。。。
//        self.showImage(imageView: self.ImgView, url: (self.imagURL!))
        // カスタムのキャッシュ設定を使用して画像をダウンロードし、表示する
        let cache = SDImageCache.shared
        cache.config.maxDiskSize = 100 * 1024 * 1024 // 最大キャッシュサイズを100 MBに設定
        cache.config.maxMemoryCost = 50 * 1024 * 1024 // メモリ中の最大キャッシュコストを50 MBに設定
        
        // 画像のURL
        let imageUrl = URL(string: (self.imagURL)!)
        // SDWebImageを使用して画像を非同期でダウンロードし、表示する
        self.ImgView.sd_setImage(with: imageUrl, placeholderImage: nil, options: [.refreshCached], context: [.imageThumbnailPixelSize: CGSize(width: 100, height: 100)])
        
//        self.ImgView.sd_setImage(with: NSURL(string: (self.imagURL!)) as URL?)
    }
    
    
    @IBAction func BackBtn(_ sender: Any)
    {
        self.dismiss(animated: true, completion: nil)
    }
}
