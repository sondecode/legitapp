//
//  BannerImageView.swift
//  LegitApp
//

import SwiftUI
import Kingfisher

struct BannerImageView: View {
    let imageURL: URL

    private var isGIF: Bool {
        imageURL.pathExtension.lowercased() == "gif"
    }

    var body: some View {
        Group {
            if isGIF {
                KFAnimatedImage(imageURL)
                    .placeholder {
                        placeholder
                    }
                    .scaledToFill()
            } else {
                KFImage(imageURL)
                    .resizable()
                    .placeholder {
                        placeholder
                    }
                    .aspectRatio(contentMode: .fill)
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.secondary.opacity(0.08)

            ProgressView()
                .controlSize(.small)
        }
    }
}
