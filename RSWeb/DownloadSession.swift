//
//  DownloadSession.swift
//  RSWeb
//
//  Created by Brent Simmons on 3/12/16.
//  Copyright © 2016 Ranchero Software, LLC. All rights reserved.
//

import Foundation

@objc public class DownloadSession: NSObject {
	
	let delegate: DownloadSessionDelegate
	let progress: DownloadProgress!
	var urlSession: URLSession!
	
	var tasksInProgress = Set<URLSessionTask>()
	var tasksPending = Set<URLSessionTask>()
	var taskIdentifierToInfoDictionary = [Int: DownloadInfo]()
	let representedObjects = NSMutableSet()
	var redirectCache = [String: String]()
	
	public init(delegate: DownloadSessionDelegate, progress: DownloadProgress, sessionConfiguration: URLSessionConfiguration) {
		self.delegate = delegate
		self.progress = progress
		super.init()
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
		
	}
	
}

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

// MARK: - Internal

extension DownloadSession {
	
	func updateProgress() {
		
		progress.numberRemaining = tasksInProgress.count + tasksPending.count
		if progress.numberRemaining < 1 {
			progress.clear()
			representedObjects.removeAllObjects()
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
