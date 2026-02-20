//
//  SettingsButtonView.swift
//  ResearchClubApp
//
//  Created by Daniel James on 2/19/26.
//

import SwiftUI
import AppKit

struct SettingsButtonView: View {
    @Binding var showSettings: Bool
    
    var body: some View {
        Menu {
            Button(action: {
                showSettings = true
            }) {
                Label("API Key Manager", systemImage: "key.fill")
            }
            
            Divider()
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Label("Quit", systemImage: "power")
            }
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .menuStyle(.borderlessButton)
        .fixedSize()
        .frame(width: 44, height: 44, alignment: .topLeading)
        .padding(.leading, 8)
        .padding(.top, 8)
    }
}
