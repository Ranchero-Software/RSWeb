//
//  APIResult.swift
//  RSWeb
//
//  Created by Maurice Parker on 5/2/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import Foundation

public typealias APIResultBlock = ((APIResult) -> ())

public final class APIResult {
	
	public var response: URLResponse?
	public var error: Error?
	public var jsonError: Error?
	public var statusCode = 0
	public var data: Data?
	
	public var jsonObject: Any? {
		
		guard let data = data, !data.isEmpty else {
			return nil
		}
		
		var result: Any?
		do {
			result = try JSONSerialization.jsonObject(with: data, options: [])
		} catch {
			jsonError = error
		}
		
		return result
		
	}
	
	public var resultString: String? {
		if let data = data {
			return String(data: data, encoding: .utf8)
		}
		return nil
	}
	
	static func resultWithRequest(response: URLResponse?, data: Data?, error: Error?) -> APIResult {
		let result = APIResult()
		result.response = response
		result.statusCode = (response as! HTTPURLResponse).statusCode
		result.data = data
		result.error = error
		return result
	}
	
}
