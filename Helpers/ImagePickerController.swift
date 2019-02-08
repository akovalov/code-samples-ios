//
//  ImagePickerController.swift
//
//
//  Created by Alex Kovalov on 2/14/17.
//  Copyright © 2017 . All rights reserved.
//

import Foundation
import UIKit

let defaultMaxImageSize = CGSize(width: 1024, height: 1024)

class ImagePickerController: UIImagePickerController {
    
    static let shared = ImagePickerController()
    
    typealias PickerCompletion = ((_ image: UIImage?, _ mediaInfo: [String: Any]?) -> Void)
    
    // MARK: Properties
    
    var completion: PickerCompletion?
    var fromVC: UIViewController?
    var maxImageSize: CGSize?
    
    
    // MARK: Lifecycle
    
    // MARK: Actions
    
    func pick(fromVC: UIViewController, maxImageSize: CGSize? = nil, completion: @escaping PickerCompletion)  {
        
        self.completion = completion
        self.fromVC = fromVC
        self.maxImageSize = maxImageSize
        
        delegate = self
        
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertVC.addAction(UIAlertAction(title: "Сделать фото".localized, style: .default, handler: { [unowned self] (action) in
            self.showPicker(with: .camera)
        }))
        alertVC.addAction(UIAlertAction(title: "Выбрать из галереи".localized, style: .default, handler: { (action) in
            
            self.showPicker(with: .photoLibrary)
        }))
        alertVC.addAction(UIAlertAction(title: "Отмена".localized, style: .cancel, handler: nil))
        fromVC.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showPicker(with sourceType: UIImagePickerControllerSourceType) {
        
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            return
        }
        
        self.sourceType = sourceType
        fromVC?.present(self, animated: true, completion: nil)
    }
}


// MARK: UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension ImagePickerController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        dismiss(animated: true) {
            self.completion?(nil, nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var image = info[UIImagePickerControllerOriginalImage] as? UIImage
        if maxImageSize != nil {
            image = image?.scaled(toSize: maxImageSize!, mode: .aspectFit)
        }
        image = image?.fixedOrientation()
        
        dismiss(animated: true) {
            self.completion?(image, info)
        }
    }
}
