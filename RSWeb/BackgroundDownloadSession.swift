//
//  BackgroundDownloadSession.swift
//  RSWeb
//
//  Created by Maurice Parker on 4/25/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import Foundation

@objc public final class BackgroundDownloadSession: DownloadSession {
	
	#if os(iOS)
	public static var completionHandler: (() -> Void)?
	#endif
	
	public init(delegate: DownloadSessionDelegate) {
		
		let sessionConfiguration  = URLSessionConfiguration.background(withIdentifier: "BackgroundDownloadSession")
		#if os(iOS)
		sessionConfiguration.sessionSendsLaunchEvents = true
		#endif
		sessionConfiguration.shouldUseExtendedBackgroundIdleMode = true

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
		
		for oneObject in objects {
			
			if !representedObjects.contains(oneObject) {
				representedObjects.add(oneObject)
				addDownloadTask(oneObject as AnyObject)
			}
			
		}
		
	}
}

#if os(iOS)
extension BackgroundDownloadSession {
	public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
		DispatchQueue.main.async {
			BackgroundDownloadSession.completionHandler?()
			BackgroundDownloadSession.completionHandler = nil
		}
	}
}
#endif

// MARK: - URLSessionDownloadDelegate

extension BackgroundDownloadSession: URLSessionDownloadDelegate {
	
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

private extension BackgroundDownloadSession {
	
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
		
		let task = urlSession.downloadTask(with: requestToUse)
		
		let info = DownloadInfo(representedObject, urlRequest: requestToUse)
		taskIdentifierToInfoDictionary[task.taskIdentifier] = info
		
		tasksPending.insert(task)
		task.resume()
		
		progress.addToNumberOfTasks(1)
		updateProgress()
		
	}

}
