//
//  NewMessageViewController.swift
//  AuthFP
//
//  Created by Abraham Lara Granados on 7/25/17.
//  Copyright © 2017 Abraham Lara Granados. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class NewMessageViewController: UITableViewController {
    
    var cellId = "cellId"
    
    var users = [User]()//For keeping tableview of existing users. User.swift will be a model[example] for what a cell chould contain

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        navigationItem.title = "New Messages"
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        fetchUser()
        
    }
    
    func fetchUser() {
                                            //Checks for all existing users in database
        
        Database.database().reference().child("AuthFP App Users").observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {

                let user = User()
                //App will crash using this setter if your class properties doesn't exactly match up with firebase dictionary keys:
//                user.setValuesForKeys(dictionary)
                //For some reason even though firebse keys are the same, app will still crash giving an exception error stating a
                //variabel does not exist witin the user class
                
                user.id = snapshot.key
                user.name = dictionary["name"] as? String
                user.email = dictionary["email"] as? String
                user.profileImageURL = dictionary["profileImageURL"] as? String
                
                self.users.append(user)
                
                //this will crash because of background thread, so lets use DispatchQueue.main.async to fix
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
                
            }
        
        }, withCancel: nil)
    }
    
    @objc func handleCancel() {
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
                                            //will render each row with existing users information
        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        
        if let userProfileImageUrl = user.profileImageURL {
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: userProfileImageUrl)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    var viewMessagesController: ViewMessagesController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        dismiss(animated: true) {
            print("Successfully dismissed ViewController")
            
            let user = self.users[indexPath.row]
            self.viewMessagesController?.showChatControllerForUser(user: user)
        }
        
    }
}
