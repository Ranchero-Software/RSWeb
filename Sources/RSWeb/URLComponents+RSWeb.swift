//
//  URLComponents.swift
//  
//
//  Created by Maurice Parker on 11/8/20.
//

import Foundation

public extension URLComponents {
	
    	// `+` is a valid character in query component as per RFC 3986 (https://developer.apple.com/documentation/foundation/nsurlcomponents/1407752-queryitems)
 	// workaround:
 	// - http://www.openradar.me/24076063
 	// - https://stackoverflow.com/a/37314144
	var enhancedPercentEncodedQuery: String? {
		return percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B").replacingOccurrences(of: "%20", with: "+")
	}
	
}
