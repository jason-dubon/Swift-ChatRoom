//
//  AuthManager.swift
//  ChatRoom
//
//  Created by Jason Dubon on 4/8/23.
//

import UIKit
import FirebaseAuth

class AuthManager {
    
    static let shared = AuthManager()
    
    private init() {}
    
    func signIn(cred: AuthCredential) {
        Auth.auth().signIn(with: cred) { result, error in
            guard let user = result?.user, error == nil else {
                return
            }
            
            let chatVC = UINavigationController(rootViewController: ChatRoomViewController(currentUser: user))
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(vc: chatVC)
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
}
