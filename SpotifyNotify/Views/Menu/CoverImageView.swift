//
//  CoverImageView.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2025/01/22.
//  Copyright © 2025 Szymon Maślanka. All rights reserved.
//

import SwiftUI

struct CoverImageView: View {
    @State private var shouldShowAlbumName = false
    
    let image: Image
    let album: String?
    
    var body: some View {
        ZStack {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .blur(radius: 100)
                .offset(x: 0, y: 5)
                .opacity(shouldShowAlbumName ? 0.3 : 1)
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .blur(radius: 20)
                .offset(x: 0, y: 5)
                .opacity(shouldShowAlbumName ? 0.3 : 1)
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .opacity(shouldShowAlbumName ? 0.3 : 1)
            
            if let album = album {
                Text(album)
                    .padding()
                    .font(.body)
                    .minimumScaleFactor(0.8)
                    .shadow(color: Color.black, radius: 3)
                    .opacity(shouldShowAlbumName ? 1 : 0)
            }
        }
        .onHover { isHovering in
            withAnimation {
                shouldShowAlbumName = isHovering
            }
        }
        .animation(.default, value: image)
    }
}
