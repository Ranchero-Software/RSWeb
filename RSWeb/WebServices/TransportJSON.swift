//
//  JSONTransport.swift
//  RSWeb
//
//  Created by Maurice Parker on 5/6/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import Foundation

extension Transport {
	
	/**
	 Sends an HTTP get and returns JSON object(s)
	 */
	public func send<R: Decodable>(request: URLRequest, resultType: R.Type, completion: @escaping (Result<(HTTPURLResponse, R?), Error>) -> Void) {
		
		send(request: request) { result in
			
			switch result {
			case .success(let (response, data)):
				do {
					if let data = data, !data.isEmpty {
						let decoder = JSONDecoder()
						decoder.dateDecodingStrategy = .iso8601
						let decoded = try decoder.decode(R.self, from: data)
						completion(.success((response, decoded)))
					} else {
						completion(.success((response, nil)))
					}
				} catch {
					completion(.failure(error))
				}
			case .failure(let error):
				completion(.failure(error))
			}
			
		}
		
	}
	
	/**
	Sends the specified HTTP method with a JSON payload.
	*/
	public func send<P: Encodable>(request: URLRequest, method: String, payload: P, completion: @escaping (Result<Void, Error>) -> Void) {
		
		var postRequest = request
		postRequest.addValue("application/json; charset=utf-8", forHTTPHeaderField: HTTPRequestHeader.contentType)

		let data: Data
		do {
			data = try JSONEncoder().encode(payload)
		} catch {
			completion(.failure(error))
			return
		}
		
		send(request: postRequest, method: method, payload: data) { result in
			
			switch result {
			case .success(_, _):
				completion(.success(()))
			case .failure(let error):
				completion(.failure(error))
			}

		}
		
	}
	
	/**
	Sends the specified HTTP method with a JSON payload and returns JSON object(s).
	*/
	public func send<P: Encodable, R: Decodable>(request: URLRequest, method: String, payload: P, resultType: R.Type, completion: @escaping (Result<(HTTPURLResponse, R?), Error>) -> Void) {
		
		var postRequest = request
		postRequest.addValue("application/json; charset=utf-8", forHTTPHeaderField: HTTPRequestHeader.contentType)

		let data: Data
		do {
			data = try JSONEncoder().encode(payload)
		} catch {
			completion(.failure(error))
			return
		}
		
		send(request: postRequest, method: method, payload: data) { result in
			
			switch result {
			case .success(let (response, data)):
				do {
					if let data = data, !data.isEmpty {
						let decoder = JSONDecoder()
						decoder.dateDecodingStrategy = .iso8601
						let decoded = try decoder.decode(R.self, from: data)
						completion(.success((response, decoded)))
					} else {
						completion(.success((response, nil)))
					}
				} catch {
					completion(.failure(error))
				}
			case .failure(let error):
				completion(.failure(error))
			}

		}
		
	}
	
}
