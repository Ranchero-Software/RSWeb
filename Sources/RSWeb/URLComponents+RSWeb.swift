//
//  URLComponents.swift
//  
//
//  Created by Maurice Parker on 11/8/20.
//

import Foundation

public extension URLComponents {
	
	var enhancedPercentEncodedQuery: String? {
		return percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B").replacingOccurrences(of: "%20", with: "+")
	}
	
}
