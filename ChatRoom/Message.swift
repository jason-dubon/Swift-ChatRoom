//
//  Message.swift
//  ChatRoom
//
//  Created by Jason Dubon on 4/8/23.
//

import Foundation

struct Message: Decodable {
    let text: String
    let photoURL: String
    let uid: String
    let createdAt: Date
}
