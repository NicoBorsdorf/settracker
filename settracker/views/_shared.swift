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
                .fill(
                    colorScheme == .dark
                        ? Color(.secondarySystemBackground)
                        : Color(.systemBackground)
                )
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

struct StopwatchCard: View {
    // Stopwatch state
    @Binding var stopwatchSeconds: Int
    //var infoText: String? = nil // override the info text in the card, usage with the localization key
    
    @State private var stopwatchRunning: Bool = false
    private let stopwatchTimer =
        Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("stopwatch").font(.headline)
                    Spacer()
                    Button(stopwatchRunning ? "Stop" : "Start") {
                        stopwatchRunning.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    Button("reset") {
                        stopwatchRunning = false
                        stopwatchSeconds = 0
                    }
                    .disabled(stopwatchSeconds == 0 && !stopwatchRunning)
                }

                Text(formattedTime(stopwatchSeconds))
                    .font(
                        .system(
                            size: 36,
                            weight: .semibold,
                            design: .monospaced
                        )
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onReceive(stopwatchTimer) { _ in
                        if stopwatchRunning {
                            stopwatchSeconds += 1
                        }
                    }

                // Helper text
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text(
                       "savingTime"
                    )
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            }
        }
    }

    private func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
