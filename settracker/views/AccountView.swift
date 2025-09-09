//
//  AccountView.swift
//  settracker
//
//  Created by Nico Borsdorf on 28.07.25.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var viewModel: AppViewModel

    @State private var isSyncing = false
    @State private var lastSync: Date? = nil
    @State private var syncError: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    appearanceCard
                    icloudCard
                    trackingCard
                    aboutCard
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(Text("account"))
        }
        .preferredColorScheme(colorScheme(for: viewModel.settings.theme))
        .tint(.accentColor)
        .alert(
            AppError.networkError.errorDescription ?? "Sync error",
            isPresented: Binding(
                get: { syncError != nil },
                set: { if !$0 { syncError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(syncError ?? "")
        }
    }

    // MARK: - Cards

    private var appearanceCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("appearance")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Picker("theme", selection: $viewModel.settings.theme) {
                    Text("System").tag(AppTheme.system)
                    Text("Light").tag(AppTheme.light)
                    Text("Dark").tag(AppTheme.dark)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("themePicker")
            }
        }
    }

    private var icloudCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("iCloud")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    if isSyncing {
                        ProgressView()
                            .tint(.secondary)
                    }
                }

                if let last = lastSync {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.secondary)
                        Text(
                            "\(String(localized: "lastSynced")): \(last.formatted(date: .abbreviated, time: .shortened))"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                } else {
                    Text("notSynced")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Spacer()
                    Button {
                        //Task { await syncNow() }
                    } label: {
                        Label("syncNow", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    private var trackingCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("tracking")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                VStack(spacing: 4){
                    Toggle("timeExercises", isOn: $viewModel.settings.timeExercises)
                        .accessibilityLabel("timeExercises")
                    HStack{
                        Text("timeExercisesInfo").font(.caption2).foregroundStyle(.gray)
                        Spacer()
                    }
                }
               
                VStack(spacing: 4){
                    Toggle("timeTrainings", isOn: $viewModel.settings.timeTrainings)
                        .accessibilityLabel("timeTrainings")
                    HStack{
                        Text("timeTrainingsInfo").font(.caption2).foregroundStyle(.gray)
                        Spacer()
                    }
                }

            }
        }
    }

    private var aboutCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("about")
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack {
                    Text("Version")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(appVersionString())
                        .foregroundStyle(.secondary)
                }

                /*Divider().background(.separator)
                
                NavigationLink("privacyPolicy") {
                    Text("Privacy Policy goes here...")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.background)
                }
                
                NavigationLink("termsOfService") {
                    Text("Terms of Service goes here...")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.background)
                }*/
            }
        }
    }

    // MARK: - Helpers

    private func colorScheme(for theme: AppTheme) -> ColorScheme? {
        switch theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
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
    @Previewable @Environment(\.modelContext) var context
    AccountView().environmentObject(
        AppViewModel(context: context)
    )
}
