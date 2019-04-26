//
//  DefaultDownloadSession.swift
//  RSWeb
//
//  Created by Maurice Parker on 4/25/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import Foundation

@objc public final class DefaultDownloadSession: DownloadSession {
	
	public init(delegate: DownloadSessionDelegate) {
		
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
		
		super.init(delegate: delegate, sessionConfiguration: sessionConfiguration)

	}
	
	override public func downloadObjects(_ objects: NSSet) {
		
		var numberOfTasksAdded = 0
		
		for oneObject in objects {
			
			if !representedObjects.contains(oneObject) {
				representedObjects.add(oneObject)
				addDataTask(oneObject as AnyObject)
				numberOfTasksAdded += 1
			}
		}
		
		progress.addToNumberOfTasks(numberOfTasksAdded)
		updateProgress()
	}
	
}

// MARK: - URLSessionDataDelegate

extension DownloadSession: URLSessionDataDelegate {
	
	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
		
		tasksInProgress.insert(dataTask)
		tasksPending.remove(dataTask)
		
		if let info = infoForTask(dataTask) {
			info.urlResponse = response
		}
		
		if response.forcedStatusCode == 304 {
			
			if let representedObject = infoForTask(dataTask)?.representedObject {
				delegate.downloadSession(self, didReceiveNotModifiedResponse: response, representedObject: representedObject)
			}
			
			completionHandler(.cancel)
			removeTask(dataTask)
			
			return
		}
		
		if !response.statusIsOK {
			
			if let representedObject = infoForTask(dataTask)?.representedObject {
				delegate.downloadSession(self, didReceiveUnexpectedResponse: response, representedObject: representedObject)
			}
			
			completionHandler(.cancel)
			removeTask(dataTask)
			
			return
		}
		
		completionHandler(.allow)
	}
	
	public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		
		guard let info = infoForTask(dataTask) else {
			return
		}
		info.addData(data)
		
		if !delegate.downloadSession(self, shouldContinueAfterReceivingData: info.data as Data, representedObject: info.representedObject) {
			
			info.canceled = true
			dataTask.cancel()
			removeTask(dataTask)
		}
	}
	
}

// MARK: - Private

private extension DownloadSession {
	
	func addDataTask(_ representedObject: AnyObject) {
		
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
		
		let task = urlSession.dataTask(with: requestToUse)
		
		let info = DownloadInfo(representedObject, urlRequest: requestToUse)
		taskIdentifierToInfoDictionary[task.taskIdentifier] = info
		
		tasksPending.insert(task)
		task.resume()
	}
	
}
