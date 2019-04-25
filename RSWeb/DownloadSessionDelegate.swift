//
//  DownloadSessionDelegate.swift
//  RSWeb
//
//  Created by Maurice Parker on 4/25/19.
//  Copyright © 2019 Ranchero Software. All rights reserved.
//

import Foundation

public protocol DownloadSessionDelegate {
	
	func downloadSession(_ downloadSession: DownloadSession, requestForRepresentedObject: AnyObject) -> URLRequest?
	
	func downloadSession(_ downloadSession: DownloadSession, downloadDidCompleteForRepresentedObject: AnyObject, response: URLResponse?, data: Data, error: NSError?)
	
	func downloadSession(_ downloadSession: DownloadSession, shouldContinueAfterReceivingData: Data, representedObject: AnyObject) -> Bool
	
	func downloadSession(_ downloadSession: DownloadSession, didReceiveUnexpectedResponse: URLResponse, representedObject: AnyObject)
	
	func downloadSession(_ downloadSession: DownloadSession, didReceiveNotModifiedResponse: URLResponse, representedObject: AnyObject)
	
}
