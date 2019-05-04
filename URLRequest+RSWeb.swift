//
//  URLRequest+RSWeb.swift
//  RSWeb
//
//  Created by Brent Simmons on 12/27/16.
//  Copyright © 2016 Ranchero Software, LLC. All rights reserved.
//

import Foundation

public extension URLRequest {
	
	init(url: URL, credentials: Credentials) {
		
		self.init(url: url)
		
		guard let username = credentials.username, let password = credentials.password else {
			return
		}
		
		let data = "\(username):\(password)".data(using: .utf8)
		let base64 = data?.base64EncodedString()
		let auth = "Basic \(base64 ?? "")"
		setValue(auth, forHTTPHeaderField: "Authorization")
		
	}
	
	// Experimental. Returns nil if scheme isn't http or https (about:blank, for instance).
	func loadingURL() -> URL? {
		
		guard let url = mainDocumentURL else {
			return nil
		}
		guard url.isHTTPOrHTTPSURL() else {
			return nil
		}
		guard !url.absoluteString.isEmpty else {
			return nil
		}
		
		return url
	}
}
