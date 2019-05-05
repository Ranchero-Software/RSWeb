//
//  Credentials.swift
//  RSWeb
//
//  Created by Brent Simmons on 12/9/17.
//  Copyright © 2017 Ranchero Software. All rights reserved.
//

import Foundation

public enum CredentialsError: Error {
	case incompleteCredentials
	case unhandledError(status: OSStatus)
}

public enum Credentials {
	case basic(username: String, password: String)
//	case oauth2(token: String)
}

