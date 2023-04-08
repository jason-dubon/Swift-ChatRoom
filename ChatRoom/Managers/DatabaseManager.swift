//
//  DatabaseManager.swift
//  ChatRoom
//
//  Created by Jason Dubon on 4/8/23.
//

import Foundation
import FirebaseFirestore
import Combine

class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private init() {}
    
    let database = Firestore.firestore()

    var updatedMessagesPublisher = PassthroughSubject<[Message], Error>()
    
    func fetchAllMessages() async throws -> [Message] {
        let snapshot = try await database.collection("messages").order(by: "createdAt", descending: true).limit(to: 25).getDocuments()
        let docs = snapshot.documents
        
        var messages = [Message]()
        for doc in docs {
            let data = doc.data()
            let text = data["text"] as? String ?? "error with text"
            let uid = data["uid"] as? String ?? "error with uid"
            let photoURL = data["photoURL"] as? String ?? "error with photoURL"
            let createdAt = data["createdAt"] as? Timestamp ?? Timestamp()
            
            let msg = Message(text: text, photoURL: photoURL, uid: uid, createdAt: createdAt.dateValue())
            messages.append(msg)
        }
        listenToChangesInDatabase()
        return messages.reversed()
    }
    
    func sendMessageToDatebase(message: Message) {
        let msgData = [
            "text": message.text,
            "uid": message.uid,
            "photoURL": message.photoURL,
            "createdAt": Timestamp(date: message.createdAt)
        ] as [String : Any]
        database.collection("messages").addDocument(data: msgData)
    }
    
    func listenToChangesInDatabase() {
        database.collection("messages").order(by: "createdAt", descending: true).limit(to: 25).addSnapshotListener { [weak self] querySnapshot, error in
            guard let documents = querySnapshot?.documents, error == nil, let strongSelf = self else {
                return
            }
            
            var messages = [Message]()
            for doc in documents {
                let data = doc.data()
                let text = data["text"] as? String ?? "error with text"
                let uid = data["uid"] as? String ?? "error with uid"
                let photoURL = data["photoURL"] as? String ?? "error with photoURL"
                let createdAt = data["createdAt"] as? Timestamp ?? Timestamp()
                
                let msg = Message(text: text, photoURL: photoURL, uid: uid, createdAt: createdAt.dateValue())
                messages.append(msg)
            }
            
            strongSelf.updatedMessagesPublisher.send(messages.reversed())
        }
        
    }

}
