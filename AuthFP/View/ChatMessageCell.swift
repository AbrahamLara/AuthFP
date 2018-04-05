//
//  ChatMessageCell.swift
//  AuthFP
//
//  Created by Abraham Lara Granados on 11/3/17.
//  Copyright © 2017 Abraham Lara Granados. All rights reserved.
//

import UIKit
import AVFoundation

class ChatMessageCell: UICollectionViewCell {
    
    var message: Message?
    
    var chatLogViewController: ChatLogViewController?
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        aiv.translatesAutoresizingMaskIntoConstraints = false
        aiv.hidesWhenStopped = true
        return aiv
        
    }()
    
    lazy var playButton: UIButton = {
       
        let btn = UIButton(type: .system)
        
        btn.setTitle("Play Video", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(named: "play")
        btn.setImage(image, for: .normal)
        btn.tintColor = UIColor.white
        btn.addTarget(self, action: #selector(handlePlay), for: .touchUpInside)
        
        return btn
    }()
    
    let textView: UITextView = {
        
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.backgroundColor = UIColor.clear
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.textColor = UIColor.white
        tv.isEditable = false //prevents user from being able to type in bubbleView
        
        return tv
    }()
    
    static let blueColor = UIColor(red: 0, green: 137/255, blue: 250/255, alpha: 1)
    
    let bubbleView: UIView = {
       
        let bv = UIView()
        bv.backgroundColor = blueColor
        bv.translatesAutoresizingMaskIntoConstraints = false
        bv.layer.cornerRadius = 16
        bv.layer.masksToBounds = true
        
        return bv
        
    }()
    
    let profileImageView: UIImageView = {
       
        let imageView = UIImageView()
        imageView.image = UIImage(named: "person-default")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        return imageView
        
    }()
    
    lazy var messageImageView: UIImageView = {
       
        let image = UIImageView();
        image.translatesAutoresizingMaskIntoConstraints = false
        image.layer.cornerRadius = 16
        image.layer.masksToBounds = true
        image.contentMode = .scaleAspectFill
        image.isUserInteractionEnabled = true
        image.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomTap)))
        
        return image
    }()
    
    var bubbleWidthAnchor: NSLayoutConstraint?
    var bubbleViewRightAnchor: NSLayoutConstraint?
    var bubbleViewLeftAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(bubbleView)
        addSubview(textView)
        addSubview(profileImageView)
        
        bubbleView.addSubview(messageImageView)
        bubbleView.addSubview(playButton)
        bubbleView.addSubview(activityIndicatorView)
        
        addElementConstraints()
    }
    
    func addElementConstraints() {
        
        //Constraints for profileImageView
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
        
        //Constraints for bubbleView
        bubbleViewRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        bubbleViewRightAnchor?.isActive = true
        
        bubbleViewLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
        
        bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        bubbleWidthAnchor?.isActive = true
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        //Constraints for textView
//        textView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 8).isActive = true
        textView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        textView.rightAnchor.constraint(equalTo:bubbleView.rightAnchor).isActive = true
//        textView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        textView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        //Contraints for messageImageView
        messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        messageImageView.widthAnchor.constraint(equalTo: bubbleView.widthAnchor).isActive = true
        messageImageView.heightAnchor.constraint(equalTo: bubbleView.heightAnchor).isActive = true
        
        activityIndicatorView.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
        activityIndicatorView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        activityIndicatorView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        //Constraints for playButton
        playButton.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
        playButton.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
    }
    
    @objc func handleZoomTap(tapGesture: UITapGestureRecognizer) {
        if message?.videoUrl != nil {
            return
        }
        
        //Pro tip: don't perform  lot of custom logic inside of a view class
        if let imageView = tapGesture.view as? UIImageView {
            self.chatLogViewController?.performZoomInForStartingImageView(startingImageView: imageView)
        }
    }
    
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    
    override func prepareForReuse() {//Prevents a glitch from occuring when playing a video and having other message cells be filled with the video playing
        super.prepareForReuse()
        player?.pause()//Video will stop playing when cell is no longer visible
        playButton.isHidden = false
        playerLayer?.removeFromSuperlayer()
        activityIndicatorView.stopAnimating()
    }
    
    @objc func handlePlay() {//When user taps on play button, video will play on bubbleView of chat message cell
        
        if let videoUrlString = message?.videoUrl, let url = URL(string: videoUrlString) {
            
            player = AVPlayer(url: url)
            
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = bubbleView.bounds//Will allow for video to be bounded to bubbleView cell
            bubbleView.layer.addSublayer(playerLayer!)
            
            player?.play()
            activityIndicatorView.startAnimating()
            playButton.isHidden = true
            print("attempting to play video....???")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
