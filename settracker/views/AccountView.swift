//
//  AccountView.swift
//  settracker
//
//  Created by Nico Borsdorf on 28.07.25.
//

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "english"
    case german = "german"

    var id: String { rawValue }
}

struct AccountView: View {
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .english

    @State private var isSyncing = false
    @State private var lastSync: Date? = nil

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Appearance
                Section(header: Text("appearance")) {
                    Picker("theme", selection: $appTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: Language
                Section(header: Text("language")) {
                    Picker("appLanguage", selection: $appLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.rawValue).tag(lang)
                        }
                    }
                }

                // MARK: iCloud Sync
                Section(header: Text("iCloud")) {
                    if let lastSync = lastSync {
                        Text(
                            "lastSynced: \(lastSync.formatted(date: .abbreviated, time: .shortened))"
                        )
                        .font(.caption)
                        .foregroundColor(.gray)
                    } else {
                        Text("notSynced")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Button {
                        syncNow()
                    } label: {
                        if isSyncing {
                            ProgressView()
                        } else {
                            Label("syncNow", systemImage: "arrow.clockwise")
                        }
                    }
                }

                // MARK: App Info
                Section(header: Text("about")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersionString())
                            .foregroundColor(.gray)
                    }

                    NavigationLink("privacyPolicy") {
                        Text("Privacy Policy goes here...")
                            .padding()
                    }

                    NavigationLink("termsOfService") {
                        Text("Terms of Service goes here...")
                            .padding()
                    }
                }
            }
            .navigationTitle("account")
        }
    }

    // MARK: - Helpers
    private func syncNow() {
        isSyncing = true
        // Simulate sync delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            lastSync = Date()
            isSyncing = false
        }
    }

    private func appVersionString() -> String {
        let version =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            ?? "?"
        let build =
            Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}

#Preview {
    AccountView()
}
