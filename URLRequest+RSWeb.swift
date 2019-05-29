//
//  URLRequest+RSWeb.swift
//  RSWeb
//
//  Created by Brent Simmons on 12/27/16.
//  Copyright © 2016 Ranchero Software, LLC. All rights reserved.
//

import Foundation

public extension URLRequest {
	
	init(url: URL, credentials: Credentials?, conditionalGet: HTTPConditionalGetInfo? = nil) {
		
		self.init(url: url)
		
		guard let credentials = credentials else {
			return
		}
		
		switch credentials {
		case .basic(let username, let password):
			let data = "\(username):\(password)".data(using: .utf8)
			let base64 = data?.base64EncodedString()
			let auth = "Basic \(base64 ?? "")"
			setValue(auth, forHTTPHeaderField: HTTPRequestHeader.authorization)
        case .googleBasicLogin(let username, let password):
            setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            httpMethod = "POST"
            let postData = "Email=\(username)&Passwd=\(password)"
            httpBody = postData.data(using: String.Encoding.utf8)
        case .googleAuthLogin(_, let apiKey):
            let auth = "GoogleLogin auth=\(apiKey)"
            setValue(auth, forHTTPHeaderField: HTTPRequestHeader.authorization)
		}
		
		guard let conditionalGet = conditionalGet else {
			return
		}
		
		// Bug seen in the wild: lastModified with last possible 32-bit date, which is in 2038. Ignore those.
		// TODO: drop this check in late 2037.
		if let lastModified = conditionalGet.lastModified, !lastModified.contains("2038") {
			setValue(lastModified, forHTTPHeaderField: HTTPRequestHeader.ifModifiedSince)
		}
		if let etag = conditionalGet.etag {
			setValue(etag, forHTTPHeaderField: HTTPRequestHeader.ifNoneMatch)
		}
		
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
