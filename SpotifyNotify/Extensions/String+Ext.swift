//
//  String+Ext.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2023/06/11.
//  Copyright © 2023 Szymon Maślanka. All rights reserved.
//

import Foundation

extension String {
    var asURL: URL? {
        .init(string: self)
    }
    
    var withLeadingZeroes: String {
        guard let int = Int(self) else { return self }
        return String(format: "%02d", int)
    }
}
