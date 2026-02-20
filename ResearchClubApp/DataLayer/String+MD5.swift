//
//  String+MD5.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import Foundation
import CryptoKit

extension String {
    var md5Hash: String {
        let data = Data(self.utf8)
        let hash = Insecure.MD5.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
