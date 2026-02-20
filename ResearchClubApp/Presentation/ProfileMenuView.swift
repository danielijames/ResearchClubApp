//
//  ProfileMenuView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI

struct ProfileMenuView: View {
    @Binding var showSettings: Bool
    @State private var isHovered = false
    
    var body: some View {
        Menu {
            Button(action: {
                showSettings = true
            }) {
                Label("Settings", systemImage: "gearshape")
            }
            
            Divider()
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Label("Quit", systemImage: "power")
            }
        } label: {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Text("DJ")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(.plain)
        .menuStyle(.borderlessButton)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
