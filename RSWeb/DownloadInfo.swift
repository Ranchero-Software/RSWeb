//
//  DownloadInfo.swift
//  RSWeb
//
//  Created by Maurice Parker on 4/25/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import Foundation

internal final class DownloadInfo {
	
	let representedObject: AnyObject
	let urlRequest: URLRequest
	let data = NSMutableData()
	var error: Error?
	var urlResponse: URLResponse?
	var canceled = false
	
	var statusCode: Int {
		return urlResponse?.forcedStatusCode ?? 0
	}
	
	init(_ representedObject: AnyObject, urlRequest: URLRequest) {
		
		self.representedObject = representedObject
		self.urlRequest = urlRequest
	}
	
	func addData(_ d: Data) {
		
		data.append(d)
	}
	
}
