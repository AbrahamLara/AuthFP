//
//  ChatLogViewController.swift
//  AuthFP
//
//  Created by Abraham Lara Granados on 7/31/17.
//  Copyright © 2017 Abraham Lara Granados. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import MobileCoreServices
import AVFoundation

class ChatLogViewController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout {
    
    var ref: DatabaseReference! = Database.database().reference().child("AuthFP App User Messages")
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
            
            observeMessages()
            
        }
    }
    
    lazy var messageField: UITextField = {
        
        let txt = UITextField()
        
        txt.placeholder = "Enter message..."
        txt.translatesAutoresizingMaskIntoConstraints = false
        txt.delegate = self
        
        return txt
    }()
    
    let sendButton: UIButton = {
        
        let button = UIButton(type: .system)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Send", for: .normal)
        button.addTarget(self, action: #selector(handleSendButton), for: .touchUpInside)
        
        return button
    }()
    
    lazy var uploadImageView: UIImageView = {
        
        let image = UIImageView()
        image.image = UIImage(named: "uploadImage")
        image.isUserInteractionEnabled = true
        image.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUploadTap)))
        
        image.translatesAutoresizingMaskIntoConstraints = false
        
        return image
    }()
    
    let messageFieldLine: UIView = {
        
        let line = UIView()
        
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = UIColor.lightGray
        
        return line
    }()
    
    //We create this so that the inputContainerView will slide along with the keyboard when appearing and disapearing
    lazy var inputContainerView: UIView = {
        
        let containerView = UIView()
        
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = UIColor.white
        containerView.addSubview(uploadImageView)
        containerView.addSubview(sendButton)
        containerView.addSubview(messageField)
        containerView.addSubview(messageFieldLine)
        
        setupElementsConstraints(containerView: containerView)
        
        return containerView
    }()
    
    let cellId = "cellId"
    
    var messages = [Message]()
    
    func observeMessages() {
        
        guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else {
            return
        }
        
        let refMessages = Database.database().reference().child("User-Messages").child(uid).child(toId)
        
        refMessages.observe(.childAdded, with: { (snapshot) in
            
            let messageId = snapshot.key
            
            self.ref.child(messageId).observe(.value, with: { (snapshot) in
                
                guard let dictionary = snapshot.value as? [String: AnyObject] else {
                    return
                }
                
                let message = Message(dictionary: dictionary)
                
                //Will allow so that the messages belonging to distinct users willl only exist. However, now that we have fixed nodes in our database so that we are observing chatlogs between two users only and not every message being made, there is no use for this code anymore
                //                if message.chatPartnerId() == self.user?.id {}
                self.messages.append(message)

                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    //scrolls to the last index when a new message is being sent
                    let indexPath = NSIndexPath(item: self.messages.count-1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath as IndexPath, at: .bottom, animated: true)
                }
            }, withCancel: nil)
            
        }, withCancel: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        //This allows for there to be 8 pixels of indent on the top of the chatlog and an indent of 8 pixels on the bottom[50 is the height of the containerView and 8 pixel indent]
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)//58 before
        
        //alows for the message cells to be dragable//
        collectionView?.alwaysBounceVertical = true
        //////////////////////////////////////////////
        collectionView?.backgroundColor = UIColor.white
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        //Allows for keyboard to dismiss while sliding chatlog
        collectionView?.keyboardDismissMode = .interactive
        setupKeyboardObservers()
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    //This funtion is neccessary for the inputAccessoryView
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func setupKeyboardObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
    
    @objc func handleKeyboardDidShow() {
        if messages.count > 0 {
            let indexPath = NSIndexPath(item: messages.count-1, section: 0)
            collectionView?.scrollToItem(at: indexPath as IndexPath, at: .top, animated: true)
        }
    }
    
    //This function prevents memory leak of line 150 being called repeatedly
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    ///////////////////////////////////////////////////////////
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    //creates the messages cell that displays messages between the user and person rececieving message
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
         
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        cell.chatLogViewController = self
        
        let message = messages[indexPath.item]
        
        cell.message = message
        
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)
        
        
        if let text = message.text {
            //A text message
            //Allows us to modify the widthAnchor constraint so that the message cells match the witdh of the message
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: text).width + 20
            cell.textView.isHidden = false
        } else if message.imageUrl != nil {
            //Falls here if message is an Image
            cell.bubbleWidthAnchor?.constant = 200
            cell.textView.isHidden = true
        }
        
        cell.playButton.isHidden = message.videoUrl == nil;
        
        return cell
    }
    
    private func setupCell(cell: ChatMessageCell, message: Message) {
        
        //Will allow for the profileIMage of the user of gray chat bubble to appear
        if let profileImageURL = self.user?.profileImageURL {
                cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageURL)
        }
        
        //determines which message should be in a gray chat bubble and which in the blue
        if message.fromId == Auth.auth().currentUser?.uid {
            //outgoing blue
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
        } else {
            //outgoing gray
            cell.bubbleView.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
        }
        
        //Allows for an image to appear as entire BubbleView
        if let messageImageUrl = message.imageUrl {
            cell.messageImageView.loadImageUsingCacheWithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = UIColor.clear
        } else {
            cell.messageImageView.isHidden = true
        }
        
    }
    
    //Creates a collectionView that represent the chat messages
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 80
        
        //returns text property from Message()
        let message = messages[indexPath.item]
        if let text = message.text { //this will make each message cell the size of the message
            height = estimateFrameForText(text: text).height + 20
        } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
            //Falls here if message is an Image
            //Geometry is needed in order to fix imageViews to proper bubbleView sizes. Formula: h1 / w1 = h2 / w2
            
            //solve for h1
            //h1 =  (h2 / w2) * w1
            
            height = CGFloat((imageHeight / imageWidth) * 200)
            
        }
        
        return CGSize(width: view.frame.width, height: height)
    }
    
    //Will fix chatlog to render all messages properly constraint to the right when phone orientation is changed
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout .invalidateLayout()
    }
    
    func estimateFrameForText(text: String) -> CGRect {
        
        //Width: 200 is taken from the constraints from the ChatMessageCell along with the 16 in the attributes
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 16)], context: nil)
        
    }
    
    func setupElementsConstraints(containerView: UIView) {
        
        //needs right, y, width, hegiht anchors: SendButton
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        //needs right, y, left, hegiht anchors: MessageField
        messageField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        messageField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        messageField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 8).isActive = true
        messageField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        //needs width, top, height, left anchors: MessageFieldLine
        messageFieldLine.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        messageFieldLine.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        messageFieldLine.heightAnchor.constraint(equalToConstant: 1).isActive = true
        messageFieldLine.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        
        //needs right, y, height, left anchors: UploadImageView
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL{//We have selected a video
            print("Here's the file url:", videoUrl)
            
            handleVideoSelectedForUrl(url: videoUrl);
            
        } else {//We have selected an Image
            
            handleImageSelectedForInfo(info: info)
            
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func handleVideoSelectedForUrl(url: URL) {
        
        let fileName = NSUUID().uuidString + "mov"
        let uploadTask = Storage.storage().reference().child("message_movies").child(fileName).putFile(from: url, metadata: nil, completion: { (metadata, error) in
            if error != nil {
                print("Failed upload of video: ", error!)
                return
            }
            
            if let videoUrl = metadata?.downloadURL()?.absoluteString {
                
                if let thumbnailImage = self.thumbnailImageForFileUrl(fileUrl: url) {
                    
                    self.uploadToFireBaseStorageUsingImage(image: thumbnailImage, completion: { (imageUrl) in
                        
                        let properties: [String: AnyObject] = ["imageUrl": imageUrl as AnyObject,
                                                               "imageWidth":  thumbnailImage.size.width as AnyObject,
                                                               "imageHeight": thumbnailImage.size.height as AnyObject,
                                                               "videoUrl":  videoUrl as AnyObject]
                        
                        self.sendMessageWithProperties(properties: properties)
                        
                    })
                }
                
            }
        })
        
        //Lets us observe and display progress of upload to firebase
        uploadTask.observe(.progress) { (snapshot) in
            
            let completedUnitCount = snapshot.progress?.completedUnitCount
            
            self.navigationItem.title = String(describing: completedUnitCount)
            
        }
        
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.name
        }
        
    }
    
    private func thumbnailImageForFileUrl(fileUrl: URL) -> UIImage? {//Generates a thumbnail from the video message being uploaded so that it can be seen as a message
        let asset = AVAsset(url: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            
            return UIImage(cgImage: thumbnailCGImage)
        } catch let err {
            print(err)
        }
        
        return nil
    }
    
    private func handleImageSelectedForInfo(info: [String: Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        //Get image out of picker
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            
            uploadToFireBaseStorageUsingImage(image: selectedImage, completion: { (imageUrl) in
                self.sendMessageWithImageURL(imageUrl: imageUrl, image: selectedImage)
            })
            
        }
        
    }
    
    private func uploadToFireBaseStorageUsingImage(image: UIImage, completion: @escaping (_ imageUrl: String) -> ()) {
        let imageName = NSUUID().uuidString
        
        let ref = Storage.storage().reference().child("messageImages").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                if(error != nil) {
                    print("Failed to upload image: ", error!)
                    return
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    completion(imageUrl)
                }
                
            })
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    //When this function is fired it will only append the text property to the dictionary values to differentiate between a message being sent and an image
    @objc func handleSendButton() {
        
        if messageField.text == "" {
            print("No message was written")
            
        } else {
            
            let properties: [String: AnyObject] = ["text": messageField.text!] as [String: AnyObject]
            
            sendMessageWithProperties(properties: properties)
        }
    }
    //When this function is fired it will only append the text property to the dictionary values to differentiate between an image being sent and a message
    private func sendMessageWithImageURL(imageUrl: String, image: UIImage) {
        
        let properties: [String: AnyObject] = ["imageWidth":  image.size.width,
                                               "imageHeight": image.size.height,
                                               "imageUrl":    imageUrl] as [String : AnyObject]
        sendMessageWithProperties(properties: properties)
    }
    
    private func sendMessageWithProperties(properties: [String: AnyObject]) {
        
        //Retrieving messages from firebase. ChildRef will keep a list of user messages to be able to support a chatlog
        
        let toId = user!.id!
        let fromId = Auth.auth().currentUser?.uid
        let timeStamp: Double = NSDate().timeIntervalSince1970
        
        var values: [String: AnyObject] = ["toId":        toId,
                                           "fromId":      fromId!,
                                           "timeStamp":   timeStamp] as [String:AnyObject]
        
        //append property values dictionary
        //key: $0, value: $1
        properties.forEach({values[$0] = $1})
        
        let childRef = ref.childByAutoId()
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil {
                print(error!)
                return
            } else {
                
                self.messageField.text = nil
                let userMessageRef = Database.database().reference().child("User-Messages").child(fromId!).child(toId)//This creates a node for the two users chatlog so no other messages are being fetched in thebackground
                
                let messageId = childRef.key
                userMessageRef.updateChildValues([messageId: 1])
                
                let recipientUserMessagesRef = Database.database().reference().child("User-Messages").child(toId).child(fromId!)//This creates a node for the two users chatlog so no other messages are being fetched in the background
                recipientUserMessagesRef.updateChildValues([messageId: 1])
                
                
            }
        }
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if messageField.text == "" {
        
            let t: Bool = true
            
            messageField.endEditing(t)
            
            return t
            
        } else {
            handleSendButton()

            let t: Bool = true

            messageField.endEditing(t)

            return t
        }
    }
    
    var startingFrame:          CGRect?
    var blackBackgroundView:    UIView?
    var startingImageView:      UIImageView?
    
    //My custom zooming Logic for when user taps on image on ChatLog
    @objc func performZoomInForStartingImageView(startingImageView: UIImageView) {
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        //When startingFrame is printed the frame dimensions are displayed
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        
        let zoomingImageView = UIImageView(frame: startingFrame!)
        
        zoomingImageView.image = startingImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            
            blackBackgroundView  = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = UIColor.black
            blackBackgroundView?.alpha = 0
            
            keyWindow.addSubview(blackBackgroundView!)
            
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1,options: .curveEaseOut, animations: {
                self.blackBackgroundView?.alpha = 1
                self.inputContainerView.alpha = 0
                
                //Math for fixing zooming frame height to equal of original image. Formula: h2 / w2 = h1 / w1
                //Solve for h2 = (startingFrame.height / startingFrame.width) * keyWindow.frame.width
                //Solve for w2 = keyWindow.frame.height / (startingFrame.height / startingFrame.width)
                
                //h2 = (h1 / w1) * w1
                let height = ((self.startingFrame?.height)! / (self.startingFrame?.width)!) * keyWindow.frame.width
                //w2 = h2 / (h1 / w1)
                let width = keyWindow.frame.height / ((self.startingFrame?.height)! / (self.startingFrame?.width)!)
                
                if keyWindow.frame.width > keyWindow.frame.height {
                    zoomingImageView.frame = CGRect(x: 0, y: 0, width: width, height: keyWindow.frame.height)
                } else {
                    zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                }
                
                zoomingImageView.center = keyWindow.center
            }, completion: nil)
        }
    }
    
    @objc func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        if let zoomOutImageView = tapGesture.view {
            
           //need to animate back out to controller
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1,options: .curveEaseOut, animations: {
                zoomOutImageView.frame = self.startingFrame!
                
                self.blackBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
            }, completion: { (completed) in
                
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            })
            
        }
    }
    
}

extension ChatLogViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func handleUploadTap() {
        let imagePickerController = UIImagePickerController()
        
        //This will bring up error unless we introduce UIImagePickerControllerDelegate and UINavigationControllerDelegate
        imagePickerController.delegate = self
        
        //can be false so that full image scale is visible and not just cropped. Write code so that the user may have to option to crop their image being sent
        imagePickerController.allowsEditing = false
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String, kUTTypeGIF as String, kUTTypePNG as String]
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
}

