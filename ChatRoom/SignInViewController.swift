//
//  SignInViewController.swift
//  ChatRoom
//
//  Created by Jason Dubon on 4/7/23.
//

import UIKit
import GoogleSignIn
import FirebaseAuth

class SignInViewController: UIViewController {
    
    let welcomeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 64, weight: .bold)
        label.text = "Welcome! Please Sign In 😃"
        label.numberOfLines = 0
        label.backgroundColor = .systemBlue
        label.textAlignment = .center
        
        return label
    }()
    
    let googleButton = GIDSignInButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureButton()
        configureGoogleSignIn()
    }
    
    private func configureButton() {
        view.addSubview(googleButton)
        googleButton.translatesAutoresizingMaskIntoConstraints = false
        googleButton.addTarget(self, action: #selector(didTapGoogleSignIn), for: .touchUpInside)
        googleButton.layer.cornerRadius = 10
        
        view.addSubview(welcomeLabel)
        
        NSLayoutConstraint.activate([
            welcomeLabel.topAnchor.constraint(equalTo: view.topAnchor),
            welcomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            welcomeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            welcomeLabel.heightAnchor.constraint(equalToConstant: 300),
            
            
            googleButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            googleButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            googleButton.widthAnchor.constraint(equalToConstant: 200),
            googleButton.heightAnchor.constraint(equalToConstant: 120),
            
            
        ])
        
    }
    
    private func configureGoogleSignIn() {
        let clientID = "1064364645449-51cb1mj27i4s5irql139seng005q6q5n.apps.googleusercontent.com"
        
        // Create Google Sign In configuration object.
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
    }
    
    @objc func didTapGoogleSignIn() {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] result, error in
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString,
                  let strongSelf = self else {
                print("error with signin")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            AuthManager.shared.signIn(cred: credential)
        }
    }
    
}
