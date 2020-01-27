//
//  String+RSWeb.swift
//  RSWeb
//
//  Created by Brent Simmons on 1/13/18.
//  Copyright © 2018 Ranchero Software. All rights reserved.
//

import Foundation

extension CharacterSet {

	/// Characters allowed in an URL query name or value.
	///
	/// Identical to `.urlQueryAllowed` without `&` or `=`.
	static let urlQueryItemAllowed: CharacterSet = {
		var allowedCharacters = CharacterSet.urlQueryAllowed
		allowedCharacters.remove(charactersIn: "&=")
		return allowedCharacters
	}()

}

public extension String {

	/// Returns `self` percent-encoded for use as a name or value in a URL query.
	var encodedForURLQuery: String? {
		return addingPercentEncoding(withAllowedCharacters: .urlQueryItemAllowed)
	}

	/// Escapes special HTML characters.
	///
	/// Escaped characters are `&`, `<`, `>`, `"`, and `'`.
	var escapedHTML: String {
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
				case "'":
					escaped.append("&apos;")
				default:
					escaped.append(char)
			}
		}

		return escaped
	}
	
}
