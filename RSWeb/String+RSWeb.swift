//
//  String+RSWeb.swift
//  RSWeb
//
//  Created by Brent Simmons on 1/13/18.
//  Copyright © 2018 Ranchero Software. All rights reserved.
//

import Foundation

extension CharacterSet {

	static let urlQueryItemAllowed: CharacterSet = {
		var allowedCharacters = CharacterSet.urlQueryAllowed
		allowedCharacters.remove(charactersIn: "&=")
		return allowedCharacters
	}()

}

public extension String {

	var encodedForURLQuery: String? {
		return addingPercentEncoding(withAllowedCharacters: .urlQueryItemAllowed)
	}
	
	var escapeHTML: String {
		var escaped = String()

		for char in self {
			switch char {
				case "&":
					escaped.append("&amp;")
				case "<":
					escaped.append("&lt;")
				case ">":
					escaped.append("&gt;")
				case "\"":
					escaped.append("&quot;")
				default:
					escaped.append(char)
			}
		}

		return escaped
	}
	
}
