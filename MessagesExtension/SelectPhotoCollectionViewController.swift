//
//  SelectPhotoCollectionViewController.swift
//  pop
//
//  Created by Sam Kirkiles on 8/14/16.
//  Copyright © 2016 Sam Kirkiles. All rights reserved.
//

import UIKit
import Messages
import Photos

private let reuseIdentifier = "Cell"

let SelectPhotoCollectionViewSegue = "SelectPhotoSegue"
let SelectPhotoCollectionViewIdentifier = "SelectPhotoID"

let CameraCellReuseIdentifier = "CameraCellID"
let HeaderReuseId = "reuseHeader"

protocol SelectPhotoDelegate {
    func sendPhoto(photo:UIImage)
    func requestStyle(presentationStyle:MSMessagesAppPresentationStyle)
}

class SelectPhotoCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, SendImageDelegate, TransitionDelegate, CameraDelegate, PresentationStyleDelegate, RequestAccessDelegate{
    
    var delegate:SelectPhotoDelegate? = nil
    
    var transitionDelegate: TransitionDelegate? = nil
    var presentationStyleDelegate: PresentationStyleDelegate? = nil
    
    var photosFetchAsset:PHFetchResult<PHAsset>?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.photosFetchAsset = self.fetchPhotos()
        
       if PHPhotoLibrary.authorizationStatus() == .authorized{
            print("Authorized")
        }else{
            self.performSegue(withIdentifier: RequestAccessSegueID, sender: self)
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == RequestAccessSegueID{
            let requestController = segue.destination as! RequestAccessToPhotosViewController
            self.transitionDelegate = requestController
            requestController.delegate = self
        }
     }
    
    
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items

        guard let fetchAssetCount = self.photosFetchAsset?.count else{
            fatalError("fetchAssetCount was nil")
        }
        
        return fetchAssetCount + 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CameraCellReuseIdentifier, for: indexPath)
            
            cell.contentView.layer.masksToBounds = true
            cell.contentView.layer.cornerRadius = 3.0
            
            cell.layer.masksToBounds = false
            cell.layer.cornerRadius = 3.0
            cell.layer.shadowOffset = CGSize(width: 3, height: 3)
            cell.layer.shadowColor = UIColor.gray.cgColor
            cell.layer.shadowRadius = 5.0
            cell.layer.shadowOpacity = 1
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
            
            return cell
        }else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoCellIdentifier, for: indexPath) as! PhotoCollectionViewCell
            

            guard let fetchAssets = self.photosFetchAsset else{
                fatalError("fetched assets was nil!!")
            }
            
            cell.imageView.image = nil

            let asset = fetchAssets.object(at: indexPath.row-1)
            cell.asset = asset
            
            DispatchQueue.global().async {
                asset.requestThumbnailImage(imageResults: {newImage,info in
                    guard let image = newImage else{
                        print(info)
                        return
                    }
                    DispatchQueue.main.async {
                        cell.imageView.image = image
                        
                    }
                })
            }
            
            cell.contentView.layer.masksToBounds = true
            cell.contentView.layer.cornerRadius = 3.0
            
            cell.layer.masksToBounds = false
            cell.layer.cornerRadius = 3.0
            cell.layer.shadowOffset = CGSize(width: 3, height: 3)
            cell.layer.shadowColor = UIColor.gray.cgColor
            cell.layer.shadowRadius = 5.0
            cell.layer.shadowOpacity = 1
            cell.layer.shouldRasterize = true
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
            
            
            return cell
            
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else{
            fatalError("Cell returned nil!")
        }
        
        
        if cell is PhotoCollectionViewCell{
            
            guard let delegate = self.delegate else{
                fatalError("delegate was nil for select photo controller")
            }
            delegate.requestStyle(presentationStyle: MSMessagesAppPresentationStyle.expanded)

            let photoCell = cell as! PhotoCollectionViewCell
            
            let drawController = storyboard?.instantiateViewController(withIdentifier: DrawViewControllerStoryboardID) as! DrawViewController
            
            photoCell.asset?.requestFullImage(imageResults: { (newImage, info) in
                guard let image = newImage else{
                    fatalError("newImage was nil")
                }
                drawController.image = image
                drawController.sendImageDelegate = self
                self.transitionDelegate = drawController
                drawController.presentationStyleDelegate = self
                self.present(drawController, animated: true, completion: {
                    //present completed
                })
            })
        }else{
            let cameraController = storyboard?.instantiateViewController(withIdentifier: CameraVCStoryboardID) as! CameraViewController
            cameraController.delegate = self
            self.transitionDelegate = cameraController
            
            guard let delegate = self.delegate else{
                fatalError("delegate was nil for select photo controller")
            }
            delegate.requestStyle(presentationStyle: MSMessagesAppPresentationStyle.expanded)

            self.present(cameraController, animated: true, completion: {
            })
        }
    }
    
    func didChooseImage(image: UIImage) {
        self.collectionView?.isUserInteractionEnabled = false
        self.dismiss(animated: false, completion: {
            
        })
        let drawController = storyboard?.instantiateViewController(withIdentifier: DrawViewControllerStoryboardID) as! DrawViewController
        drawController.image = image
        drawController.sendImageDelegate = self
        drawController.presentationStyleDelegate = self
        self.transitionDelegate = drawController
        self.present(drawController, animated: false, completion: {
            self.collectionView?.isUserInteractionEnabled = true
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width:90,height:90);
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(10, 10, 10, 10)
    }
    
    
    // MARK: Fetching Photos
    
    func fetchPhotos() -> PHFetchResult<PHAsset>{
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor.init(key: "creationDate", ascending: false)]
        let photos = PHAsset.fetchAssets(with: .image, options: options)
        return photos
    }
    
    //MARK: Send photo Delegate
    
    func sendImage(image: UIImage) {
        if let delegate = self.delegate{
            delegate.sendPhoto(photo: image)
        }else{
            fatalError("Delegate was nil!")
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        //2
        case UICollectionElementKindSectionHeader:
            //3
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,withReuseIdentifier: HeaderReuseId,for: indexPath)
            return headerView
        default:
            //4
            fatalError("kind was not found")
        }
        
    }
    
    //MARK: Transition Delegate
    
    func didTransition(presentationStyle: MSMessagesAppPresentationStyle) {
        if let delegate = self.transitionDelegate{
            delegate.didTransition(presentationStyle: presentationStyle)
        }else{
            print("transition delegate was nil on SelectPhotoViewController but continuing anywayas..")
        }
        
    }
    
    //MARK: Presentation Style
    
    func getPresentationStyle() -> MSMessagesAppPresentationStyle {
        guard let delegate = self.presentationStyleDelegate else{
            fatalError("Prsenationstyledelegate was nill on Selectphotoviewcontroller")
        }
        
        return delegate.getPresentationStyle()
    }
    
    func requestStyle(style: MSMessagesAppPresentationStyle) {
        guard let delegate = self.delegate else{
            fatalError("delegate was nil for select photo controller")
        }
        delegate.requestStyle(presentationStyle: style)
        
    }
    
    func photosAuthorized() {
        self.photosFetchAsset = fetchPhotos()

        self.collectionView?.reloadData()
    }
    
    func isCameraType() -> Bool {
        return false
    }
    
}

extension PHAsset{
    
    func requestThumbnailImage(imageResults: @escaping (UIImage?, [NSObject : AnyObject]?) -> Void){
        
        let retinaScale = UIScreen.main.scale
        let imageManager = PHCachingImageManager();
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .exact
        options.isSynchronous = true
        options.version = .current
        imageManager.requestImage(for: self, targetSize: CGSize(width: 100 * retinaScale, height:100 * retinaScale), contentMode: .aspectFill, options: options, resultHandler: {newImage,info in
            imageResults(newImage, info as [NSObject : AnyObject]?)
        })
    }
    
    
    func requestFullImage(imageResults: @escaping (UIImage?, [NSObject : AnyObject]?) -> Void){
        let imageManager = PHCachingImageManager();
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = true
        imageManager.requestImage(for: self, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFill, options: options, resultHandler: {newImage,info in
            imageResults(newImage, info as [NSObject : AnyObject]?)
        })
    }
}
