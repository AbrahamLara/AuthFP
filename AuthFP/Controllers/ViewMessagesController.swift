//
//  TabOneViewController.swift
//  AuthFP
//
//  Created by Abraham Lara Granados on 7/24/17.
//  Copyright © 2017 Abraham Lara Granados. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class ViewMessagesController: UITableViewController  {
    
    let cellId = "cellId"
    var refMessages: DatabaseReference! = Database.database().reference().child("AuthFP App User Messages")
    var messages = [Message]()
    var messagesDictionary = [String: Message]()
    var users = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "newMessage"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(handleNewMessage))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        navigationController?.navigationBar.prefersLargeTitles = true
        
        tableView.reloadData()
        setupNavigationTitle()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        observeUserMessages()
        
        tableView.allowsMultipleSelectionDuringEditing = true
        
    }
    
    //Allows for additional options for cell
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let message = self.messages[indexPath.row]
        if let chatPartnerId = message.chatPartnerId() {
            Database.database().reference().child("User-Messages").child(uid).child(chatPartnerId).removeValue(completionBlock: { (error, ref) in
                
                if error != nil {
                    print("Failed to delete message", error!)
                    return
                }
                
                self.messagesDictionary.removeValue(forKey: chatPartnerId)
                self.attemptReloadOfTable()
            })
        }
        
    }
    
    func observeUserMessages() { //This function allows for only messages sent from a certain account to appear 
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference().child("User-Messages").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            
            let userId = snapshot.key
            
            Database.database().reference().child("User-Messages").child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
                let messageId = snapshot.key
                
                self.fetchMessageWithMessageId(messageId: messageId)
                
            }, withCancel: nil)
            
        }, withCancel: nil)
        
        ref.observe(.childRemoved, with: { (snapshot) in
            
            self.messagesDictionary.removeValue(forKey: snapshot.key)
            self.attemptReloadOfTable()
            
        }, withCancel: nil)
    }
    
    private func fetchMessageWithMessageId(messageId: String) {
        
        self.refMessages.child(messageId).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                
                let message = Message(dictionary: dictionary)
                
                self.messages.append(message)
                
                //This groups up the messages to each person so that the same cells do not exist
                if let chatPartnerId = message.chatPartnerId() {//Using chatPartnerId will only allow one cell per account to appear whether a message was recieved or sent
                    
                    self.messagesDictionary[chatPartnerId] = message
                    
                }
                
                //This deals with the ViewController reloading too many times and having profile images and names appear misplaced
                self.attemptReloadOfTable()
                
            }
            
        }, withCancel: nil)
        
    }
    
    private func attemptReloadOfTable() {
        //It is best to place these here because we do not need to reconstruct the messages array everytime we get a new message. This will save a lot of computation. We just need to contruct it the moment we reload the table.
        self.messages = Array(self.messagesDictionary.values)
        
        self.messages.sort(by: { (message1, message2) -> Bool in
            
            return Double(message1.timeStamp!) > Double(message2.timeStamp!) //This allows for the latest message to appear as the first cell
            
        })
        
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
     //This is the function that deals with the ViewController realoding too many times and having profile images and names appear misplaced
    var timer: Timer?
    @objc func handleReloadTable() {
        //This will crash because of background thread so lets call this on DispatchQueue.main.async
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    //This function displays the user message in each cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        let message = messages[indexPath.row]
        cell.message = message
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let message = messages[indexPath.row]
        
        guard let chatPartnerId = message.chatPartnerId() else {
            return
        }
        
        let ref = Database.database().reference().child("AuthFP App Users").child(chatPartnerId)
        ref.observe(.value, with: { (snapshot) in
            
            guard let dictionary = snapshot.value as? [String: AnyObject] else {
                return
            }
            
            let user = User()
            
            user.id = chatPartnerId
            user.name = dictionary["name"] as? String
            user.profileImageURL = dictionary["profileImageURL"] as? String
            
            self.showChatControllerForUser(user: user)
        }, withCancel: nil)
        
        
    }
    
    @objc func showChatControllerForUser(user: User) {
        
        let chatLogController = ChatLogViewController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
        
    }
    
    func setupNavigationTitle() {
                                                    //Fetching users
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        Database.database().reference().child("AuthFP App Users").child(uid).observe(.value, with: { (snapshot) in
            
                            //After User is logged in their name and profileImage will be displayed in the NavigationBar
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                
                
                        //The following code will allow the users profile image and username to appear alongside in the center fitting for any length
                let titleView = UIView()
                
                let containerView = UIView()
                containerView.translatesAutoresizingMaskIntoConstraints = false
                titleView.addSubview(containerView)
                
                
                let profileImageView = UIImageView()
                profileImageView.translatesAutoresizingMaskIntoConstraints = false
                profileImageView.contentMode = .scaleAspectFill
                profileImageView.layer.cornerRadius = 20
                profileImageView.clipsToBounds = true
                profileImageView.image = UIImage(named: "person-default")

                if let profileImageUrl = dictionary["profileImageURL"] as? String { //Loads profile image using cache so to prevent a lot of the users network usage
                    
                    profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
                    
                }

                containerView.addSubview(profileImageView)
                
                //ios 11
                //need x, y, width, height anchors
                profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
                profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
                profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
                profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true


                let nameLabel = UILabel()
                containerView.addSubview(nameLabel)
                nameLabel.text = dictionary["name"] as? String
                nameLabel.translatesAutoresizingMaskIntoConstraints = false

                //need x, y, width, height anchors
                nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 4).isActive = true
                nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
                nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
                nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true

                containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
                containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
                
                
                self.navigationItem.title = "Messages"
                self.navigationItem.titleView = titleView
                
            }
            
        }, withCancel: nil)
    }
    
    @objc func handleLogout() {
        
        do {
            
            try Auth.auth().signOut()
            
        } catch let logoutError {
            
            print(logoutError)
            
        }
        
        let loginController = ViewController()
        self.present(loginController, animated: true, completion: nil)
        
        print("User Signed out")
    }

    @objc func handleNewMessage() {
        //Opens up NewMessageViewController
        
        let newMessageViewController = NewMessageViewController()
        newMessageViewController.viewMessagesController = self
        let newMessage = UINavigationController(rootViewController: newMessageViewController)
        self.present(newMessage, animated: true, completion: nil)
    }
    
    
}
