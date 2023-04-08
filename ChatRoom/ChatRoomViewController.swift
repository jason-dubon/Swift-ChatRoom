//
//  ViewController.swift
//  ChatRoom
//
//  Created by Jason Dubon on 4/7/23.
//

import UIKit
import FirebaseAuth
import Combine

class ChatRoomViewController: UIViewController {

    lazy var tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(ChatTableViewCell.self, forCellReuseIdentifier: ChatTableViewCell.identifier)
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = .systemBackground
        table.separatorStyle = .none
        
        return table
    }()
    
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.delegate = self
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.backgroundColor = .systemGray6
        textView.returnKeyType = .default
        textView.font = .systemFont(ofSize: 16)
        textView.textContainerInset = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        
        return textView
    }()
    
    lazy var sendImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "paperplane")
        imageView.tintColor = .label
        imageView.backgroundColor = .systemGray6
        imageView.contentMode = .scaleAspectFit
        
        imageView.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapSend))
        imageView.addGestureRecognizer(gesture)
        
        return imageView
    }()
    
    var messages = [Message]()
    var mockData = [
        "The quick brown fox jumps over the lazy dog.",
        "The cat in the hat is very fat.",
        "The boy with the toy enjoys playing in the sun.",
        "She sells seashells by the seashore.",
        "The early bird catches the worm.",
        "A picture is worth a thousand words.",
        "Actions speak louder than words.",
        "An apple a day keeps the doctor away.",
        "All that glitters is not gold.",
        "April showers bring May flowers."
    ]
    
    var tokens: Set<AnyCancellable> = []
    
    var currentUser: User!
    init(currentUser: User) {
        self.currentUser = currentUser
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        
        setUpNavBar()
        configureUI()
        subscribeToKeyboardShowHide()
        fetchMessages()
        subscribeToMessagePublisher()
    }
    
    private func setUpNavBar() {
        navigationController?.navigationBar.topItem?.title = "Chat Room"
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(didTapSignOut))
        navigationController?.navigationBar.tintColor = .systemRed
        navigationController?.navigationBar.backgroundColor = .systemBackground
    }
    
    private func configureUI() {
        view.addSubview(tableView)
        view.addSubview(textView)
        view.addSubview(sendImageView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: textView.topAnchor),
    
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            textView.trailingAnchor.constraint(equalTo: sendImageView.leadingAnchor, constant: 0),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            textView.heightAnchor.constraint(equalToConstant: 100),
            
            sendImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            sendImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sendImageView.heightAnchor.constraint(equalToConstant: 101),
            sendImageView.widthAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    private func reloadChatRoom() {
        tableView.reloadData()
        let index = IndexPath(row: messages.count-1, section: 0)
        tableView.scrollToRow(at: index, at: .bottom, animated: true)
    }
    
    @objc private func didTapSend() {
        textView.resignFirstResponder()
        if let textMessage = textView.text, textMessage.count > 2 {
            let msg = Message(text: textMessage, photoURL: currentUser.photoURL?.absoluteString ?? "", uid: currentUser.uid, createdAt: Date())
            DatabaseManager.shared.sendMessageToDatebase(message: msg)
            messages.append(msg)
            textView.text = ""
            reloadChatRoom()
        }
    }
    
    @objc private func didTapSignOut() {
        do {
            try AuthManager.shared.signOut()
            let signInVC = UINavigationController(rootViewController: SignInViewController())
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(vc: signInVC)
        } catch {
            print("error signing out")
        }
        
    }
    
// MARK: Keyboard Events
    private func subscribeToKeyboardShowHide() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        self.view.frame.origin.y = -keyboardFrame.size.height
    }
    
    @objc func keyboardWillHide(notification: Notification) {
        let info = notification.userInfo!
        let _: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        self.view.frame.origin.y = 0
    }

    // MARK: Fetch Messages
    private func fetchMessages() {
        Task {
            let msgs = try await DatabaseManager.shared.fetchAllMessages()
            self.messages = msgs
            await MainActor.run(body: {
                self.reloadChatRoom()
            })
            print(messages)
        }
    }
    
    private func subscribeToMessagePublisher() {
        DatabaseManager.shared.updatedMessagesPublisher.receive(on: DispatchQueue.main).sink { _ in
            
        } receiveValue: { messages in
            self.messages = messages
            self.tableView.reloadData()
        }.store(in: &tokens)

        
    }
}

extension ChatRoomViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatTableViewCell.identifier, for: indexPath) as? ChatTableViewCell else {
            return UITableViewCell()
        }
        let index = indexPath.row
//        if index % 2 == 0 {
//            cell.configureForMessage(message: messages[index], isUser: true)
//        } else {
//            cell.configureForMessage(message: messages[index], isUser: false)
//        }
        cell.configureForMessage(message: messages[index], currentUid: currentUser.uid)
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

extension ChatRoomViewController: UITextViewDelegate {

    
}
