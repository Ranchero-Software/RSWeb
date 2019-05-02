//
//  APICall.swift
//  RSWeb
//
//  Created by Brent Simmons on 12/9/17.
//  Copyright © 2017 Ranchero Software. All rights reserved.
//

import Foundation

// Main thread only.

public class APICall {

	let session: URLSession
	let request: URLRequest
	
	public init(session: URLSession, request: URLRequest) {
		self.session = session
		self.request = request
	}
	
	public func execute(completionHandler handler: @escaping APIResultBlock) {
		
		let task = session.dataTask(with: request) { (data, response, error) in
			
			let result = APIResult.resultWithRequest(response: response, data: data, error: error)
			
			DispatchQueue.main.async {
				handler(result)
			}
			
		}
		
		task.resume()
		
	}
	
}
