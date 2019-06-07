//
//  String+RSWeb.swift
//  RSWeb
//
//  Created by Brent Simmons on 1/13/18.
//  Copyright © 2018 Ranchero Software. All rights reserved.
//

import Foundation

public extension String {

	func encodedForURLQuery() -> String? {

		guard let encodedString = addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
			return nil
		}
		return encodedString.replacingOccurrences(of: "&", with: "%38")
	}
	
	func escapeHTML() -> String {
		var result = self.replacingOccurrences(of: "&", with: "&amp;")
		result = result.replacingOccurrences(of: "\"", with: "&quot;")
		result = result.replacingOccurrences(of: "'", with: "&#x27;")
		result = result.replacingOccurrences(of: ">", with: "&gt;")
		result = result.replacingOccurrences(of: "<", with: "&lt;")
		return result
	}
	
}
