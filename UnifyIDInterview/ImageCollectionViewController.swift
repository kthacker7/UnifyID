//
//  ImageCollectionViewController.swift
//  UnifyIDInterview
//
//  Created by Kunal Thacker on 9/20/17.
//  Copyright © 2017 Kunal Thacker. All rights reserved.
//

import UIKit
import KeychainSwift

class ImageCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    var imageKeys : [String]?
    var images: [UIImage] = []
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (imageKeys != nil) {
            return imageKeys!.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCollectionViewCell", for: indexPath) as? ImageCollectionViewCell {
            if (indexPath.row < self.images.count) {
                cell.imageView.image = self.images[indexPath.row]
                cell.descLabel.text = "Snapshot \(indexPath.row)"
            }
            return cell
        }
        return UICollectionViewCell()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let nib = UINib(nibName: "ImageCollectionViewCell", bundle: nil)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "ImageCollectionViewCell")
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.vertical
        layout.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        layout.itemSize = CGSize(width: self.view.frame.size.width / 2 , height: self.view.frame.size.height / 2)
        self.collectionView.collectionViewLayout = layout
        self.navigationItem.backBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(ImageCollectionViewController.backButtonPressed(_:)))
    }
    
    @objc func backButtonPressed(_ sender : Any) {
        self.navigationController?.popViewController(animated: true)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let keychain = KeychainSwift()
        if let keys = imageKeys {
            for key in keys {
                if let data = keychain.getData(key) {
                    if let image = UIImage(data: data) {
                        self.images.append(image)
                    }
                }
            }
        }
        self.collectionView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
