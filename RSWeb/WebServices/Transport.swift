//
//  Transport.swift
//  RSWeb
//
//  Created by Maurice Parker on 5/4/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//
// Inspired by: http://robnapier.net/a-mockery-of-protocols

import Foundation

public typealias HTTPHeaders = [AnyHashable : Any]

public enum TransportError: Error {
	case noData
	case httpError(status: Int)
}

public protocol Transport {
	func send<T: Codable>(request: URLRequest, resultType: T.Type, completion: @escaping (Result<(HTTPHeaders, T), Error>) -> Void)
	func send(request: URLRequest, completion: @escaping (Result<(HTTPHeaders, Data), Error>) -> Void)
}

extension URLSession: Transport {
	
	public func send<T: Codable>(request: URLRequest, resultType: T.Type, completion: @escaping (Result<(HTTPHeaders, T), Error>) -> Void) {
		
		send(request: request) { result in
			
			switch result {
			case .success(let (headers, data)):
				do {
					let decoder = JSONDecoder()
					let decoded = try decoder.decode(T.self, from: data)
					completion(.success((headers, decoded)))
				} catch {
					completion(.failure(error))
				}
			case .failure(let error):
				completion(.failure(error))
			}
			
		}
		
	}
	
	public func send(request: URLRequest, completion: @escaping (Result<(HTTPHeaders, Data), Error>) -> Void) {
		
		let task = self.dataTask(with: request) { (data, response, error) in
			
			if let error = error {
				return completion(.failure(error))
			}
			
			guard let response = response as? HTTPURLResponse, let data = data else {
				return completion(.failure(TransportError.noData))
			}
			
			DispatchQueue.main.async {
				switch response.forcedStatusCode {
				case 200...299:
					completion(.success((response.allHeaderFields, data)))
				default:
					completion(.failure(TransportError.httpError(status: response.forcedStatusCode)))
				}
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
