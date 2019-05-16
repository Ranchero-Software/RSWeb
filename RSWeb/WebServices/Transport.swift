//
//  Transport.swift
//  RSWeb
//
//  Created by Maurice Parker on 5/4/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//
// Inspired by: http://robnapier.net/a-mockery-of-protocols

import Foundation

public enum TransportError: LocalizedError {
	case noData
	case httpError(status: Int)
	
	public var errorDescription: String? {
		switch self {
		case .httpError(let status):
			switch status {
			case 401:
				return NSLocalizedString("User credentials are invalid or expired.", comment: "Invalid credentials")
			default:
				let msg = NSLocalizedString("An unexpected network error occurred.  HTTP Status: ", comment: "Unexpected error")
				return "\(msg) \(status)"
			}
		default:
			return NSLocalizedString("An unknown network error occurred.", comment: "Unknown error")
		}
	}
	
	public var recoverySuggestion: String? {
		switch self {
		case .httpError(let status):
			switch status {
			case 401:
				return NSLocalizedString("Please update your credentials in the application preferences.", comment: "Update preferences")
			default:
				return NSLocalizedString("Please try again later ", comment: "Try later")
			}
		default:
			return NSLocalizedString("Please try again later ", comment: "Try later")
		}
	}
	
}

public protocol Transport {
	
	/**
	Sends URLRequest and returns the HTTP headers and the data payload.
	*/
	func send(request: URLRequest, completion: @escaping (Result<(HTTPURLResponse, Data?), Error>) -> Void)
	
	/**
	Sends URLRequest that doesn't require any result information.
	*/
	func send(request: URLRequest, method: String, completion: @escaping (Result<Void, Error>) -> Void)
	
	/**
	Sends URLRequest with a data payload and returns the HTTP headers and the data payload.
	*/
	func send(request: URLRequest, method: String, payload: Data, completion: @escaping (Result<(HTTPURLResponse, Data?), Error>) -> Void)
	
}

extension URLSession: Transport {
	
	public func send(request: URLRequest, completion: @escaping (Result<(HTTPURLResponse, Data?), Error>) -> Void) {
		
		let task = self.dataTask(with: request) { (data, response, error) in
			
			if let error = error {
				return completion(.failure(error))
			}
			
			guard let response = response as? HTTPURLResponse, let data = data else {
				return completion(.failure(TransportError.noData))
			}
		
			switch response.forcedStatusCode {
			case 200...399:
				completion(.success((response, data)))
			default:
				completion(.failure(TransportError.httpError(status: response.forcedStatusCode)))
			}
		}
		
		task.resume()
		
	}

	public func send(request: URLRequest, method: String, completion: @escaping (Result<Void, Error>) -> Void) {
		
		var sendRequest = request
		sendRequest.httpMethod = method
		
		let task = self.dataTask(with: sendRequest) { (data, response, error) in
			
			if let error = error {
				return completion(.failure(error))
			}
			
			guard let response = response as? HTTPURLResponse else {
				return completion(.failure(TransportError.noData))
			}
			
			switch response.forcedStatusCode {
			case 200...399:
				completion(.success(()))
			default:
				completion(.failure(TransportError.httpError(status: response.forcedStatusCode)))
			}
		}
		
		task.resume()
		
	}
	
	public func send(request: URLRequest, method: String, payload: Data, completion: @escaping (Result<(HTTPURLResponse, Data?), Error>) -> Void) {
		
		var sendRequest = request
		sendRequest.httpMethod = method
		
		let task = self.uploadTask(with: sendRequest, from: payload) { (data, response, error) in
			
			if let error = error {
				return completion(.failure(error))
			}
			
			guard let response = response as? HTTPURLResponse, let data = data else {
				return completion(.failure(TransportError.noData))
			}
		
			switch response.forcedStatusCode {
			case 200...399:
				completion(.success((response, data)))
			default:
				completion(.failure(TransportError.httpError(status: response.forcedStatusCode)))
			}
				
		}
		
		task.resume()
		
	}
	
	public static func webserviceTransport() -> Transport {
	
		let sessionConfiguration = URLSessionConfiguration.default
		sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
		sessionConfiguration.timeoutIntervalForRequest = 60.0
		sessionConfiguration.httpShouldSetCookies = false
		sessionConfiguration.httpCookieAcceptPolicy = .never
		sessionConfiguration.httpMaximumConnectionsPerHost = 2
		sessionConfiguration.httpCookieStorage = nil
		sessionConfiguration.urlCache = nil
		
		if let userAgentHeaders = UserAgent.headers() {
			sessionConfiguration.httpAdditionalHeaders = userAgentHeaders
		}
		
		return URLSession(configuration: sessionConfiguration)
	
	}
	
}
