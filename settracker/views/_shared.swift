//
//  _shared.swift
//  settracker
//
//  Created by Nico Borsdorf on 24.08.25.
//

import SwiftUI

struct SectionCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack { content }
                .frame(maxWidth: .infinity)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(.separator), lineWidth: 0.5)
                .opacity(colorScheme == .dark ? 0.35 : 0.2)
        )
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }

    private var shadowColor: Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.06)
    }
    private var shadowRadius: CGFloat {
        colorScheme == .dark ? 0 : 6
    }
    private var shadowY: CGFloat {
        colorScheme == .dark ? 0 : 3
    }
}


