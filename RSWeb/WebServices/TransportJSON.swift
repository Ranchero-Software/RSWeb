//
//  JSONTransport.swift
//  RSWeb
//
//  Created by Maurice Parker on 5/6/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import Foundation

extension Transport {
	
	public func getJSON<T: Codable>(request: URLRequest, resultType: T.Type, completion: @escaping (Result<(HTTPHeaders, T?), Error>) -> Void) {
		
		send(request: request) { result in
			
			switch result {
			case .success(let (headers, data)):
				do {
					if let data = data {
						let decoder = JSONDecoder()
						decoder.dateDecodingStrategy = .formatted(DateFormatter.rfc3339DateFormatter)
						let decoded = try decoder.decode(T.self, from: data)
						completion(.success((headers, decoded)))
					} else {
						completion(.success((headers, nil)))
					}
				} catch {
					completion(.failure(error))
				}
			case .failure(let error):
				completion(.failure(error))
			}
			
		}
		
	}

	public func postJSON<T: Encodable>(request: URLRequest, payload: T, completion: @escaping (Result<Void, Error>) -> Void) {
		var postRequest = request
		postRequest.httpMethod = HTTPMethod.post
		postRequest.addValue("application/json; charset=utf-8", forHTTPHeaderField: HTTPRequestHeader.contentType)
		encodeAndSend(request: postRequest, payload: payload, completion: completion)
	}
	
}

private extension Transport {
	
	func encodeAndSend<T: Encodable>(request: URLRequest, payload: T, completion: @escaping (Result<Void, Error>) -> Void) {
		
		let data: Data
		do {
			data = try JSONEncoder().encode(payload)
		} catch {
			completion(.failure(error))
			return
		}
		
		send(request: request, data: data) { result in
			
			switch result {
			case .success(_, _):
				completion(.success(()))
			case .failure(let error):
				completion(.failure(error))
			}
			
		}
		
	}
	
}
