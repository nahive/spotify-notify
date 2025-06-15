//
//  MusicTrack+Validation.swift
//  Notify
//
//  Created by Szymon Maślanka on 2025/01/16.
//  Copyright © 2025 Szymon Maślanka. All rights reserved.
//

import Foundation

extension MusicTrack {
    static func validated(from track: MusicTrack?) -> MusicTrack? {
        guard let track = track else { 
            System.log("Track validation failed: nil track", level: .debug)
            return nil
        }

        guard !track.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !track.artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !track.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            System.log("Track validation failed: empty required fields", level: .debug)
            return nil
        }
        
        let invalidNames = ["Unknown", "N/A", "", "-", "null", "undefined"]
        let trackNameLower = track.name.lowercased()
        let artistNameLower = track.artist.lowercased()
        
        for invalidName in invalidNames {
            if trackNameLower == invalidName.lowercased() || artistNameLower == invalidName.lowercased() {
                System.log("Track validation failed: invalid name or artist", level: .debug)
                return nil
            }
        }
    
        if let duration = track.duration, duration <= 0 {
            System.log("Track validation failed: invalid duration", level: .debug)
            return nil
        }
        
        System.log("Track validated successfully: \(track.name) by \(track.artist)", level: .debug)
        return track
    }
} 