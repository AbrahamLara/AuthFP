//
//  Extensions.swift
//  AuthFP
//
//  Created by Abraham Lara Granados on 7/28/17.
//  Copyright © 2017 Abraham Lara Granados. All rights reserved.
//

import UIKit

let imageCache = NSCache<AnyObject, UIImage>()

extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(urlString: String) {//This function returns userProfileImage using the image url
        
//        self.image = nil                  //optional
        
        //check cache for image first
        
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject) {
            self.image = cachedImage
            return
        }
        
        //Otherwise fire off a new download
        
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            
            //download hit an error so lets return out
            if error != nil {
                print(error!)
                return
            } else  {
                DispatchQueue.main.async {
                    
                    if let downloadedImage = UIImage(data: data!) {
                        imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                        
                        
                        self.image = downloadedImage
                    }
                }
            }
            
        }).resume()
    }
}
