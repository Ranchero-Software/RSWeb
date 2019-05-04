//
//  BasicCredentials.swift
//  RSWeb
//
//  Created by Maurice Parker on 5/4/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import Foundation

public struct BasicCredentials: Credentials {
	
	public var username: String?
	public var password: String?
	
	public init(username: String, password: String) {
		self.username = username
		self.password = password
	}
	
}
