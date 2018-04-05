//
//  ViewController.swift
//  AuthFP
//
//  Created by Abraham Lara Granados on 7/19/17.
//  Copyright © 2017 Abraham Lara Granados. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import UserNotifications

class ViewController: UIViewController, UITextFieldDelegate {
    
    var ref: DatabaseReference! = Database.database().reference()
    
    let inputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    let registerButton: UIButton =  {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 80/255, green: 101/255, blue: 161/255, alpha: 1)
        button.setTitle("Enter", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(clickedRegister), for: .touchUpInside)
        button.isHidden = false
        button.layer.cornerRadius = 5;
        return button
    }()
    
    let loginButton: UIButton =  {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 80/255, green: 101/255, blue: 161/255, alpha: 1)
        button.setTitle("Enter", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(clickedLogin(sender:)), for: .touchUpInside)
        button.isHidden = true
        button.layer.cornerRadius = 5;
        return button
    }()
    
    lazy var nameTextField: UITextField = {
        
        let tf = UITextField()
        tf.placeholder = "Name"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.delegate = self
        
        return tf
    }()
    
    let nameSeparatorView: UIView = {
        let view  = UIView()
        view.backgroundColor = UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var emailTextField: UITextField = {
        
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.delegate = self
        tf.keyboardType = UIKeyboardType.emailAddress
        
        return tf
    }()
    
    let emailSeparatorView: UIView = {
        let view  = UIView()
        view.backgroundColor = UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var passwordTextField: UITextField = {
        
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.isSecureTextEntry = true
        tf.delegate = self
        
        return tf
    }()
    
    lazy var profileImageView: UIImageView = {//Lazy var enables us to access self from within closure block
        
        let imageView = UIImageView()
        imageView.image = UIImage(named: "person-default")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleSelectProfileImageView)))
        imageView.isUserInteractionEnabled = true
        imageView.layer.cornerRadius = 80
        imageView.clipsToBounds = true
        return imageView
    }()
    
    let userOptionControl: UISegmentedControl = {
        let to = UISegmentedControl(items: ["Login", "Register"])
        to.selectedSegmentIndex = 1
        to.tintColor = UIColor.white
        to.translatesAutoresizingMaskIntoConstraints = false
        to.addTarget(self, action: #selector(handleLoginRegisterChange), for: .valueChanged)
        return to
    }()
    
    let messageOutput: UILabel = {
       
        let mo = UILabel()
        mo.textAlignment = .center
        mo.translatesAutoresizingMaskIntoConstraints = false
        mo.textColor = UIColor.white
        mo.font = UIFont(name: "Helvetica", size: 25)
        mo.text = "Fill in all fields"
        return mo
    }()
//                                                                          Elements end here
    
    var inputsContainerViewHeightAnchor: NSLayoutConstraint?
    var nameTextFieldHeightAnchor: NSLayoutConstraint?
    var emailTextFieldHeightAnchor: NSLayoutConstraint?
    var passwordTextFieldHeightAnchor: NSLayoutConstraint?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //This will request the user to allow the app to recieve Notifications or not
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (success, error) in

            if error != nil {
                print("Autherization Unssuccessful")
            } else {
                print("Autherization Successful")
            }
        }
        
        self.view.backgroundColor = UIColor(red: 61/255, green: 91/255, blue: 151/255, alpha: 1)
        
        view.addSubview(inputContainerView)
        view.addSubview(registerButton)
        view.addSubview(profileImageView)
        view.addSubview(userOptionControl)
        view.addSubview(messageOutput)
        view.addSubview(loginButton)
        
        setupElementsConstraints()
        
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//                                                                      Functions start here
    
    @objc func handleLoginRegisterChange() {
        
        //change height of inputContainerView
        inputsContainerViewHeightAnchor?.constant = userOptionControl.selectedSegmentIndex == 0 ? 100 : 150
        
        //change height of nameTextField
        nameTextFieldHeightAnchor?.isActive = false
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor, multiplier: userOptionControl.selectedSegmentIndex == 0 ? 0 : 1/3)
        nameTextFieldHeightAnchor?.isActive = true
        
        //change height of emailTextField
        emailTextFieldHeightAnchor?.isActive = false
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor, multiplier: userOptionControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        emailTextFieldHeightAnchor?.isActive = true
        
        //change height of passwordTextField
        passwordTextFieldHeightAnchor?.isActive = false
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor, multiplier: userOptionControl.selectedSegmentIndex == 0 ? 1/2 : 1/3)
        passwordTextFieldHeightAnchor?.isActive = true
        
        //Switching betweem login and register buttons
        loginButton.isHidden = userOptionControl.selectedSegmentIndex == 0 ? false : true
        registerButton.isHidden = userOptionControl.selectedSegmentIndex == 0 ? true : false
        
        if userOptionControl.selectedSegmentIndex == 0 {
            
            self.messageOutput.text = "Type Email and Password"
            self.messageOutput.textColor = UIColor.white
            
        } else {
            
            self.messageOutput.text = "Fill in all fields"
            self.messageOutput.textColor = UIColor.white
            
        }
        
    }

    func setupElementsConstraints() {
        //need x, y, width, height constraints: InputContainerView
        
        inputContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        inputContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        inputContainerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        inputsContainerViewHeightAnchor = inputContainerView.heightAnchor.constraint(equalToConstant: 150)
        self.inputsContainerViewHeightAnchor?.isActive = true
        
        //adding elements
        inputContainerView.addSubview(nameTextField)
        inputContainerView.addSubview(nameSeparatorView)
        inputContainerView.addSubview(emailTextField)
        inputContainerView.addSubview(emailSeparatorView)
        inputContainerView.addSubview(passwordTextField)
        
        //need x, y, width, height constraints: ProfileViewImage
        profileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        profileImageView.bottomAnchor.constraint(equalTo: messageOutput.topAnchor, constant: -13).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 160).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 160).isActive = true
        
        //need x, y, width, height constraints: NameTextField
        nameTextField.leftAnchor.constraint(equalTo: inputContainerView.leftAnchor, constant: 12).isActive = true
        nameTextField.topAnchor.constraint(equalTo: inputContainerView.topAnchor).isActive = true
        nameTextField.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive = true
        nameTextFieldHeightAnchor = nameTextField.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor, multiplier: 1/3)
         self.nameTextFieldHeightAnchor?.isActive = true
        
        //need x, y, width, height constraints: NameSeperatorView
        nameSeparatorView.leftAnchor.constraint(equalTo: inputContainerView.leftAnchor).isActive = true
        nameSeparatorView.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
        nameSeparatorView.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive = true
        nameSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        //need x, y, width, height constraints: EmailTextField
        emailTextField.leftAnchor.constraint(equalTo: inputContainerView.leftAnchor, constant: 12).isActive = true
        emailTextField.topAnchor.constraint(equalTo: nameTextField.bottomAnchor).isActive = true
        emailTextField.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive = true
        emailTextFieldHeightAnchor = emailTextField.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor, multiplier: 1/3)
        self.emailTextFieldHeightAnchor?.isActive = true
        
        //need x, y, width, height constraints: EmailSeperatorView
        emailSeparatorView.leftAnchor.constraint(equalTo: inputContainerView.leftAnchor).isActive = true
        emailSeparatorView.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        emailSeparatorView.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive = true
        emailSeparatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        //need x, y, width, height constraints: PasswordTextField
        passwordTextField.leftAnchor.constraint(equalTo: inputContainerView.leftAnchor, constant: 12).isActive = true
        passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor).isActive = true
        passwordTextField.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive = true
        passwordTextFieldHeightAnchor = passwordTextField.heightAnchor.constraint(equalTo: inputContainerView.heightAnchor, multiplier: 1/3)
        self.passwordTextFieldHeightAnchor?.isActive = true
        
        //need x, y, width, height constraints: RegisterButton
        registerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        registerButton.topAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: 12).isActive = true
        registerButton.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive = true
        registerButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        //need x, y, width, height constraints: LoginButton
        loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginButton.topAnchor.constraint(equalTo: inputContainerView.bottomAnchor, constant: 12).isActive = true
        loginButton.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive = true
        loginButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        //need x, y, width, height constraints: UserOptionControl
        userOptionControl.bottomAnchor.constraint(equalTo: inputContainerView.topAnchor, constant: -4.5).isActive = true
        userOptionControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        userOptionControl.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive = true
        userOptionControl.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        //need x, y, width, height constraints: MessageOutput
        messageOutput.bottomAnchor.constraint(equalTo: userOptionControl.topAnchor, constant: -10).isActive = true
        messageOutput.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        messageOutput.widthAnchor.constraint(equalTo: inputContainerView.widthAnchor).isActive = true
        messageOutput.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
    }

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        let t: Bool = true
        
        nameTextField.endEditing(t)
        emailTextField.endEditing(t)
        passwordTextField.endEditing(t)
        
        return t
    }
}

