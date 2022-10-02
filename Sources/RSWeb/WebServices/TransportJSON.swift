//
//  JSONTransport.swift
//  RSWeb
//
//  Created by Maurice Parker on 5/6/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import Foundation
import os.log

extension Transport {
	
	/**
	 Sends an HTTP get and returns JSON object(s)
	 */
    public func send<R: Decodable>(request: URLRequest, resultType: R.Type, dateDecoding: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecoding: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys, completion: @escaping (Result<(HTTPURLResponse, R?), Error>) -> Void) {
		
		send(request: request) { result in
			DispatchQueue.main.async {

				switch result {
				case .success(let (response, data)):
					if let data = data, !data.isEmpty {
						// PBS 27 Sep. 2019: decode the JSON on a background thread.
						// The profiler says that this is 45% of what’s happening on the main thread
						// during an initial sync with Feedbin.
						DispatchQueue.global(qos: .background).async {
							let decoder = JSONDecoder()
							decoder.dateDecodingStrategy = dateDecoding
							decoder.keyDecodingStrategy = keyDecoding
							do {
								let decoded = try decoder.decode(R.self, from: data)
								DispatchQueue.main.async {
									completion(.success((response, decoded)))
								}
							}
							catch {
								error.log()
								DispatchQueue.main.async {
									completion(.failure(error))
								}
							}
						}
					}
					else {
						completion(.success((response, nil)))
					}

				case .failure(let error):
					completion(.failure(error))
				}
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
			DispatchQueue.main.async {
				switch result {
				case .success((_, _)):
					completion(.success(()))
				case .failure(let error):
					completion(.failure(error))
				}
			}
		}
	}
	
	/**
	Sends the specified HTTP method with a JSON payload and returns JSON object(s).
	*/
	public func send<P: Encodable, R: Decodable>(request: URLRequest, method: String, payload: P, resultType: R.Type, dateDecoding: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecoding: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys, completion: @escaping (Result<(HTTPURLResponse, R?), Error>) -> Void) {
		
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
			DispatchQueue.main.async {

				switch result {
				case .success(let (response, data)):
					do {
						if let data = data, !data.isEmpty {
							let decoder = JSONDecoder()
							decoder.dateDecodingStrategy = dateDecoding
                            decoder.keyDecodingStrategy = keyDecoding
							let decoded = try decoder.decode(R.self, from: data)
							completion(.success((response, decoded)))
						} else {
							completion(.success((response, nil)))
						}
					} catch {
						error.log()
						completion(.failure(error))
					}
				case .failure(let error):
					completion(.failure(error))
				}
			}
		}
	}

    /**
     Sends the specified HTTP method with a Raw payload and returns JSON object(s).
     */
	public func send<R: Decodable>(request: URLRequest, method: String, data: Data, resultType: R.Type, dateDecoding: JSONDecoder.DateDecodingStrategy = .iso8601, keyDecoding: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys, completion: @escaping (Result<(HTTPURLResponse, R?), Error>) -> Void) {

		send(request: request, method: method, payload: data) { result in
			DispatchQueue.main.async {
				
				switch result {
				case .success(let (response, data)):
					do {
						if let data = data, !data.isEmpty {
							let decoder = JSONDecoder()
							decoder.dateDecodingStrategy = dateDecoding
							decoder.keyDecodingStrategy = keyDecoding
							let decoded = try decoder.decode(R.self, from: "a bunch of bullshit".data(using: .utf8)!)
							completion(.success((response, decoded)))
						} else {
							completion(.success((response, nil)))
						}
					} catch {
						error.log()
						completion(.failure(error))
					}
				case .failure(let error):
					completion(.failure(error))
				}
			}
		}
	}
}

extension Error {
	
	var logger: Logger {
		Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Transport")
	}

	var usableErrorDescription: String {
		guard let decodingError = self as? DecodingError else { return localizedDescription }
		
		var errorDesc = "JSON "
		
		switch decodingError {
		case .typeMismatch(let type, let context):
			errorDesc += "Type Mismatch for \(type). \(context.description)"
		case .valueNotFound(let type, let context):
			errorDesc += "Value Not Found for \(type). \(context.description)"
		case .keyNotFound(let key, let context):
			errorDesc += "Key Not Found for \(key). \(context.description)"
		case .dataCorrupted(let context):
			errorDesc += "Data Corrupted. \(context.description)"
		default:
			errorDesc += "Error: \(localizedDescription)"
		}
	
		return errorDesc
	}
	
	func log() {
		logger.error("\(usableErrorDescription, privacy: .public)")
	}

}

extension DecodingError.Context {
	var description: String {
		var d = String()
		if let localizedDescription = underlyingError?.localizedDescription {
			d += "Error: \(localizedDescription) "
		}
		return "\(d)Coding Path: \(codingPath)"
	}
}
