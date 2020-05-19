//
//  MacWebBrowser.swift
//  RSWeb
//
//  Created by Brent Simmons on 12/27/16.
//  Copyright © 2016 Ranchero Software, LLC. All rights reserved.
//

import AppKit

public class MacWebBrowser {

	/// Opens a URL in the default browser.
	@discardableResult public class func openURL(_ url: URL, inBackground: Bool = false) -> Bool {
		
		guard let preparedURL = url.preparedForOpeningInBrowser() else {
			return false
		}
		
		if (inBackground) {
			do {
				try NSWorkspace.shared.open(preparedURL, options: [.withoutActivation], configuration: [:])
				return true
			}
			catch {
				return false
			}
		}
		
		return NSWorkspace.shared.open(preparedURL)
	}

	/// Returns an array of MacWebBrowser, sorted by name.
	public class func sortedBrowsers() -> [MacWebBrowser] {
		guard let browserIDs = LSCopyAllHandlersForURLScheme("https" as CFString)?.takeRetainedValue() as? [String] else {
			return []
		}

		return browserIDs.compactMap { MacWebBrowser(bundleIdentifier: $0) }.sorted {
			if let leftName = $0.name, let rightName = $1.name {
				return leftName < rightName
			}

			return false
		}
	}

	/// The filesystem URL of the default web browser.
	private class var defaultBrowserURL: URL? {
		return NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https:///")!)
	}

	/// The user's default web browser.
	public class var `default`: MacWebBrowser {
		return MacWebBrowser(url: defaultBrowserURL!)
	}

	/// The filesystem URL of the web browser.
	let url: URL

	/// The application icon of the web browser.
	public lazy var icon: NSImage? = {
		if let values = try? url.resourceValues(forKeys: [.effectiveIconKey]) {
			return values.effectiveIcon as? NSImage
		}

		return nil
	}()

	/// The localized name of the web browser, with any `.app` extension removed.
	public lazy var name: String? = {
		if let values = try? url.resourceValues(forKeys: [.localizedNameKey]), var name = values.localizedName {
			if let extensionRange = name.range(of: ".app", options: [.anchored, .backwards]) {
				name = name.replacingCharacters(in: extensionRange, with: "")
			}

			return name
		}

		return nil
	}()

	/// The bundle identifier of the web browser.
	public lazy var bundleIdentifier: String? = {
		return Bundle(url: url)?.bundleIdentifier
	}()

	/// Initializes a `MacWebBrowser` with a URL on disk.
	/// - Parameter url: The filesystem URL of the browser.
	public init(url: URL) {
		self.url = url
	}

	/// Initializes a `MacWebBrowser` from a bundle identifier.
	/// - Parameter bundleIdentifier: The bundle identifier of the browser.
	public convenience init?(bundleIdentifier: String) {
		guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
			return nil
		}

		self.init(url: url)
	}

	/// Opens a URL in this browser.
	/// - Parameters:
	///   - url: The URL to open.
	///   - inBackground: If `true`, attempt to load the URL without bringing the browser to the foreground.
	@discardableResult public func openURL(_ url: URL, inBackground: Bool = false) -> Bool {
		guard let preparedURL = url.preparedForOpeningInBrowser() else {
			return false
		}

		let options: NSWorkspace.LaunchOptions = inBackground ? [.withoutActivation] : []

		return NSWorkspace.shared.open([preparedURL], withAppBundleIdentifier: self.bundleIdentifier, options: options, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
	}

}

extension MacWebBrowser: CustomDebugStringConvertible {

	public var debugDescription: String {
		if let name = name, let bundleIdentifier = bundleIdentifier{
			return "MacWebBrowser: \(name) (\(bundleIdentifier))"
		} else {
			return "MacWebBrowser"
		}
	}
}

private extension URL {
	
	func preparedForOpeningInBrowser() -> URL? {
		
		var urlString = absoluteString.replacingOccurrences(of: " ", with: "%20")
		urlString = urlString.replacingOccurrences(of: "^", with: "%5E")
		urlString = urlString.replacingOccurrences(of: "&amp;", with: "&")
		urlString = urlString.replacingOccurrences(of: "&#38;", with: "&")
		
		return URL(string: urlString)
	}	
}
