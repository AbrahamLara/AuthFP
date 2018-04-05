//
//  UserCell.swift
//  AuthFP
//
//  Created by Abraham Lara Granados on 8/7/17.
//  Copyright © 2017 Abraham Lara Granados. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

//We use hack to use subtitle label because porgrammtically we don't have access to what the table view cells types are. So to fix this we register a different cell
class UserCell: UITableViewCell {
    
    var refUsers: DatabaseReference! = Database.database().reference().child("AuthFP App Users")
    
    var message: Message? {
        didSet{
            
            setupNameAndProfileImage()
            
            self.detailTextLabel?.textColor = UIColor.gray
            self.detailTextLabel?.font = UIFont.italicSystemFont(ofSize: 13)
            
            if message?.videoUrl != nil {
                
                message?.text = "Video was sent..."
                self.detailTextLabel?.text = message?.text
                
            } else if message?.imageUrl != nil {
                
                message?.text = "Image was sent..."
                self.detailTextLabel?.text = message?.text
                
            } else {
                
                self.detailTextLabel?.text = message?.text
                
            }
            
            if let seconds = message?.timeStamp {
                
                let timeStampDate       = NSDate(timeIntervalSince1970: seconds)
                let dateFormater        = DateFormatter()
                dateFormater.dateFormat = "hh:mm:ss a"
                timeLabel.text          = dateFormater.string(from: timeStampDate as Date)
            }
        }
    }
    
    private func setupNameAndProfileImage() {
       
        
        //Accesses User profile Name
        if let id = message?.chatPartnerId() {
            refUsers.child(id).observe(.value, with: { (snapshot) in
                
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    
                    self.textLabel?.text = dictionary["name"] as? String
                    
                    if let profileImageURL = dictionary["profileImageURL"] as? String {//Displays the user profileimage on the cell of corresponding name and message
                        self.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageURL)
                    }
                }
            }, withCancel: nil)
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textLabel?.frame = CGRect(x: 64, y: textLabel!.frame.origin.y - 2, width: textLabel!.frame.width, height: textLabel!.frame.height)
        detailTextLabel?.frame = CGRect(x: 64, y: detailTextLabel!.frame.origin.y + 2, width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height)
    }
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "person-default")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 24
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let timeLabel: UILabel = {
       
        let label = UILabel()
        
//        label.text = "HH:MM:SS"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.lightGray
        return label
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        addSubview(timeLabel)
        
        setupElementConstraints()
        
    }
    
    func setupElementConstraints() {
        //ios 11 constraint anchor
        //need x, y, width, height anchors
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 48).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        //need x, y, width, height anchors
        timeLabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        timeLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 18).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        timeLabel.heightAnchor.constraint(equalTo: (textLabel?.heightAnchor)!).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
