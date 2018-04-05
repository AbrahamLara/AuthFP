//
//  ViewController+handlers.swift
//  AuthFP
//
//  Created by Abraham Lara Granados on 7/27/17.
//  Copyright © 2017 Abraham Lara Granados. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func clickedRegister() {
                                                            //Firebase Auth functions
        
        Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
            if (self.emailTextField.text?.isEqual(""))! || (self.passwordTextField.text?.isEqual(""))! || (self.nameTextField.text?.isEqual(""))! {
                
                self.messageOutput.text = "Must fill in all fields!!"
                self.messageOutput.textColor = UIColor.red
                print("Textfields have not been completely filled out")
                
            } else if error != nil {
                
                self.messageOutput.text = "Email already in use"
                self.messageOutput.textColor = UIColor.red
                print("Email input already exist")
                
            } else {
                
                let uid = user?.uid
                                                            //Firebase Storage Functions
                let name = self.nameTextField.text!
                let email = self.emailTextField.text!
                let imageName = NSUUID().uuidString
                let storageRef = Storage.storage().reference().child("AuthFP_App_Users_Profile_Images").child("\(imageName).jpg")
                
                
                if let uploadData = UIImageJPEGRepresentation(self.profileImageView.image!, 0.1) {//Image conpression so images load faster
                    
                    storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                        
                        if error != nil {
                            print(error!)
                            return
                        }
                        if let profileImageURL = metadata?.downloadURL()?.absoluteString {
                            let userInformation = ["name": name,
                                                   "email": email,
                                                   "profileImageURL": profileImageURL]
                            
                            self.registerUserIntoDatabaseWithUID(uid: uid!, userInformation: userInformation as [String : AnyObject])
                        }
                        
                    })
                    
                }
                
                self.messageOutput.text = "User Created"
                self.messageOutput.textColor = UIColor.white
                print("User has been created")
                
            }
        }
    }
    
    @objc func clickedLogin(sender: UIButton) {
        //Firebase Auth functions
        
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) { (user, error) in
            if (self.emailTextField.text?.isEqual(""))! || (self.passwordTextField.text?.isEqual(""))! {
                
                self.messageOutput.text = "Must fill in both fields!!"
                self.messageOutput.textColor = UIColor.red
                print("Textfields have not been completely fill out")
                
            } else if error != nil {
                
                self.messageOutput.text = "Invalid Email or Password"
                self.messageOutput.textColor = UIColor.red
                print("Inavlid Email or password input")
                
            } else {
                
                self.messageOutput.text = "Signed In"
                self.messageOutput.textColor = UIColor.white
                
                let TOVC = UINavigationController(rootViewController: ViewMessagesController())
                
                self.present(TOVC, animated: true, completion: nil)
                print("Successfully Signed in user")
                
            }
        }
    }
    
    private func registerUserIntoDatabaseWithUID(uid: String, userInformation: [String: AnyObject]) {
                                                            //Firebase Database Functions
        
        let userReference = self.ref.child("AuthFP App Users").child(uid)
        userReference.updateChildValues(userInformation, withCompletionBlock: { (error, ref) in
            
            if error != nil {
                
                print(error!)
                return
                
            } else {
                
                print("Successfully saved user into database")
                
            }
            
        })
    }
    
    @objc func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
        
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
                                                    //Get image out of picker
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
