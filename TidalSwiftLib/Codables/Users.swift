//
//  User.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftUI

public struct User: Decodable, Identifiable {
	public let id: Int
	public let username: String
	public let firstName: String
	public let lastName: String
	public let email: String
	public let countryCode: String
	public let created: Date
	public let picture: String?
	public let newsletter: Bool
	public let acceptedEULA: Bool
	public let gender: String
	public let dateOfBirth: Date
	public let facebookUid: Int?
	public let appleUid: String?
	
	public func pictureUrl(session: Session, resolution: Int) -> URL? {
		guard let picture = picture else { return nil }
		return session.imageUrl(imageId: picture, resolution: resolution)
	}
	
	public func picture(session: Session, resolution: Int) -> NSImage? {
		guard let picture = picture else { return nil }
		return session.image(imageId: picture, resolution: resolution)
	}
}

struct LoginUser: Decodable {
	let userId: Int
	let email: String?
	let countryCode: String
	let fullName: String?
	let firstName: String?
	let lastName: String?
	let nickname: String?
	let username: String
	let address: String?
	let city: String?
	let postalcode: String?
	let usState: String?
	let phoneNumber: String?
	let birthday: String?
	let gender: String?
	let imageId: String?
	let channelId: Int?
	let parentId: Int?
	let acceptedEULA: Bool
	let created: Int
	let updated: Int
	let facebookUid: Int?
	let appleUid: String?
	let newUser: Bool
}


struct Client: Decodable {
	let id: Int
	let name: String
	let authorizedForOffline: Bool
	let authorizedForOfflineDate: Date?
}

struct Sessions: Decodable {
	let sessionId: UUID
	let userId: Int
	let countryCode: String
	let channelId: Int
	let partnerId: Int
	let client: Client
}

public struct SubscriptionType: Decodable {
	public let type: String
	public let offlineGracePeriod: Int
}

public struct Subscription: Decodable {
	public let validUntil: Date
	public let status: String
	public let subscription: SubscriptionType
	public let highestSoundQuality: AudioQuality
	public let premiumAccess: Bool
	public let canGetTrial: Bool
	public let paymentType: String
}
