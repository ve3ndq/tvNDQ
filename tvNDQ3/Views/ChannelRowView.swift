//
//  ChannelRowView.swift
//  tvNDQ3
//
//  Created by Nathan Dykstra on 2025-09-18.
//

import SwiftUI

struct ChannelRowView: View {
    let channel: Channel
    let isFavorite: Bool
    let onPlay: () -> Void
    let onToggleFavorite: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(channel.name)
                    .font(.body)
                    .lineLimit(1)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(isFavorite ? .red : .gray)
                    .font(.body)
            }
            .buttonStyle(.plain)
            
            Button(action: onPlay) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Play")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(4)
                .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .background(Color.clear)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .focused($isFocused)
    }
}