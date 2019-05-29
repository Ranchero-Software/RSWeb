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
    case googleBasicLogin(username: String, password: String, url: URL)
    case googleAuthLogin(username: String, apiKey: String, url: URL)
//	case oauth2(token: String)
}

