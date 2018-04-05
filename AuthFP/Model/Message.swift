//
//  Message.swift
//  AuthFP
//
//  Created by Abraham Lara Granados on 8/5/17.
//  Copyright © 2017 Abraham Lara Granados. All rights reserved.
//

import UIKit
import FirebaseAuth

class Message: NSObject {
    
    var fromId: String?
    var text: String?
    var timeStamp: Double?
    var toId: String?
    var imageUrl: String?
    var imageWidth: NSNumber?
    var imageHeight: NSNumber?
    var videoUrl: String?
    
    //This logic will let cells show the latest messages either sent and recieved from the proper userand profile image
    
    func chatPartnerId() -> String? {

        return fromId == Auth.auth().currentUser?.uid ? toId : fromId

    }
    
    init(dictionary: [String: AnyObject]) {
        super.init()
        
        fromId      = dictionary["fromId"]      as? String
        text        = dictionary["text"]        as? String
        timeStamp   = dictionary["timeStamp"]   as? Double
        toId        = dictionary["toId"]        as? String
        imageUrl    = dictionary["imageUrl"]    as? String
        imageWidth  = dictionary["imageWidth"]  as? NSNumber
        imageHeight = dictionary["imageHeight"] as? NSNumber
        videoUrl    = dictionary["videoUrl"]    as? String
    }
}
