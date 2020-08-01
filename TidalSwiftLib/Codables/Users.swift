//
//  User.swift
//  TidalSwiftLib
//
//  Created by Melvin Gundlach on 01.08.20.
//  Copyright © 2020 Melvin Gundlach. All rights reserved.
//

import Foundation
import SwiftUI

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
	public let facebookUid: Int
	
	public func getPictureUrl(session: Session, resolution: Int) -> URL? {
		guard let picture = picture else { return nil }
		return session.getImageUrl(imageId: picture, resolution: resolution)
	}
	
	public func getPicture(session: Session, resolution: Int) -> NSImage? {
		guard let picture = picture else { return nil }
		return session.getImage(imageId: picture, resolution: resolution)
	}
}
