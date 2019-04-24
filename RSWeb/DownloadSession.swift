//
//  DownloadSession.swift
//  RSWeb
//
//  Created by Brent Simmons on 3/12/16.
//  Copyright © 2016 Ranchero Software, LLC. All rights reserved.
//

import Foundation

// Create a DownloadSessionDelegate, then create a DownloadSession.
// To download things: call downloadObjects, with a set of represented objects, to download things. DownloadSession will call the various delegate methods.

public protocol DownloadSessionDelegate {

	func downloadSession(_ downloadSession: DownloadSession, requestForRepresentedObject: AnyObject) -> URLRequest?

	func downloadSession(_ downloadSession: DownloadSession, downloadDidCompleteForRepresentedObject: AnyObject, response: URLResponse?, data: Data, error: NSError?)

	func downloadSession(_ downloadSession: DownloadSession, shouldContinueAfterReceivingData: Data, representedObject: AnyObject) -> Bool

}


@objc public final class DownloadSession: NSObject {
	
	public static var sessionConfig: URLSessionConfiguration?
	#if os(iOS)
	public static var completionHandler: (() -> Void)?
	#endif
	
	public var progress = DownloadProgress(numberOfTasks: 0)

	private var urlSession: URLSession!
	private var tasksInProgress = Set<URLSessionTask>()
	private var tasksPending = Set<URLSessionTask>()
	private var taskIdentifierToInfoDictionary = [Int: DownloadInfo]()
	private let representedObjects = NSMutableSet()
	private let delegate: DownloadSessionDelegate
	private var redirectCache = [String: String]()
	
	public init(delegate: DownloadSessionDelegate) {
		
		self.delegate = delegate

		super.init()
		
		let sessionConfiguration: URLSessionConfiguration
		if let sessionConfig = DownloadSession.sessionConfig {
			sessionConfiguration = sessionConfig
		} else {
			sessionConfiguration = URLSessionConfiguration.default
		}
		
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

		urlSession = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)		
	}
	
	deinit {
		urlSession.invalidateAndCancel()
	}

	// MARK: - API

	public func cancel() {

		// TODO
	}

	public func downloadObjects(_ objects: NSSet) {

		for oneObject in objects {

			if !representedObjects.contains(oneObject) {
				representedObjects.add(oneObject)
				addDownloadTask(oneObject as AnyObject)
			}
			
		}

	}
}

#if os(iOS)
extension DownloadSession: URLSessionDelegate {
	public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
		DispatchQueue.main.async {
			DownloadSession.completionHandler?()
			DownloadSession.completionHandler = nil
		}
	}
}
#endif

// MARK: - URLSessionTaskDelegate

extension DownloadSession: URLSessionTaskDelegate {

	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		
		tasksInProgress.remove(task)
		
		guard let info = infoForTask(task) else {
			return
		}
		
		info.error = error

		delegate.downloadSession(self, downloadDidCompleteForRepresentedObject: info.representedObject, response: info.urlResponse, data: info.data as Data, error: error as NSError?)

		removeTask(task)
	}
	
	public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
		
		if response.statusCode == 301 || response.statusCode == 308 {
			if let oldURLString = task.originalRequest?.url?.absoluteString, let newURLString = request.url?.absoluteString {
				cacheRedirect(oldURLString, newURLString)
			}
		}
		
		completionHandler(request)
	}
}

// MARK: - URLSessionDownloadDelegate

extension DownloadSession: URLSessionDownloadDelegate {
	
	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		
		guard let data = try? Data(contentsOf: location), let info = infoForTask(downloadTask) else {
			return
		}
		info.addData(data)
		
		if !delegate.downloadSession(self, shouldContinueAfterReceivingData: info.data as Data, representedObject: info.representedObject) {
			
			info.canceled = true
			downloadTask.cancel()
			removeTask(downloadTask)
		}
		
	}
	
}

// MARK: - Private

private extension DownloadSession {

	func updateProgress() {
		
		progress.numberRemaining = tasksInProgress.count + tasksPending.count
		if progress.numberRemaining < 1 {
			progress.clear()
			representedObjects.removeAllObjects()
		}
	}
	
	func addDownloadTask(_ representedObject: AnyObject) {

		guard let request = delegate.downloadSession(self, requestForRepresentedObject: representedObject) else {
			return
		}

		var requestToUse = request
		
		// If received permanent redirect earlier, use that URL.
		
		if let urlString = request.url?.absoluteString, let redirectedURLString = cachedRedirectForURLString(urlString) {
			if let redirectedURL = URL(string: redirectedURLString) {
				requestToUse.url = redirectedURL
			}
		}
		
		DispatchQueue.global().async { [weak self] in
			guard let task = self?.urlSession.downloadTask(with: requestToUse) else {
				return
			}
			DispatchQueue.main.async { [weak self] in
				
				let info = DownloadInfo(representedObject, urlRequest: requestToUse)
				self?.taskIdentifierToInfoDictionary[task.taskIdentifier] = info
				
				self?.tasksPending.insert(task)
				task.resume()
				
				self?.progress.addToNumberOfTasks(1)
				self?.updateProgress()
				
			}
		}
		
	}

	func infoForTask(_ task: URLSessionTask) -> DownloadInfo? {

		return taskIdentifierToInfoDictionary[task.taskIdentifier]
	}

	func removeTask(_ task: URLSessionTask) {

		tasksInProgress.remove(task)
		tasksPending.remove(task)
		taskIdentifierToInfoDictionary[task.taskIdentifier] = nil
		updateProgress()
	}
	
	func urlStringIsBlackListedRedirect(_ urlString: String) -> Bool {
		
		// Hotels and similar often do permanent redirects. We can catch some of those.
		
		let s = urlString.lowercased()
		let badStrings = ["solutionip", "lodgenet", "monzoon", "landingpage", "btopenzone", "register", "login", "authentic"]
		
		for oneBadString in badStrings {
			if s.contains(oneBadString) {
				return true
			}
		}
		
		return false
	}
	
	func cacheRedirect(_ oldURLString: String, _ newURLString: String) {
		
		if urlStringIsBlackListedRedirect(newURLString) {
			return
		}
		
		redirectCache[oldURLString] = newURLString
	}
	
	func cachedRedirectForURLString(_ urlString: String) -> String? {
		
		// Follow chains of redirects, but avoid loops.
		
		var urlStrings = Set<String>()
		urlStrings.insert(urlString)
		
		var currentString = urlString
		
		while(true) {
			
			if let oneRedirectString = redirectCache[currentString] {
				
				if urlStrings.contains(oneRedirectString) {
					// Cycle. Bail.
					return nil
				}
				urlStrings.insert(oneRedirectString)
				currentString = oneRedirectString
			}
				
			else {
				break
			}
		}
		
		return currentString == urlString ? nil : currentString
	}
}

// MARK: - DownloadInfo

private final class DownloadInfo {
	
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

