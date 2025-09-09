//
//  HomeView.swift
//  settracker
//
//  Created by Nico Borsdorf on 28.07.25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
            NavigationStack {
                VStack {
                   listView
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("trainingLog")
                .toolbar{
                    NavigationLink(destination: TrainingView(
                        training: Training()
                    ), label: {
                        Label("", systemImage: "plus")
                    })
                }
            }
    }

    // MARK: list
    private var listView: some View {
        let groupedTrainings = groupTrainingsByWeek(viewModel.trainings)
        return List {
            ForEach(
                groupedTrainings,
                id: \.week
            ) { group in
                Section(header: Text(group.weekString)) {
                    ForEach(group.trainings) { training in
                        NavigationLink {
                            TrainingView(training: training)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(training.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                }
                                Spacer()
                                typeTag(for: training.type)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: tag
    private func typeTag(for type: TrainingType) -> some View {
        let (color, text) = tagStyle(for: type)
        let textComponent = Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(color.opacity(0.3)))
        
        if #available(iOS 26.0, *){
            return textComponent.glassEffect(.clear, in: .rect(cornerRadius: 8))
        } else {
            return textComponent
        }
    }

    private func tagStyle(for type: TrainingType) -> (Color, String) {
        switch type {
        case .none:
            return (.clear, "")
        case .strength:
            return (.red, "strength")
        case .cardio:
            return (.green, "cardio")
        }
    }
}

#Preview {
    @Previewable @Environment(\.modelContext) var context
    HomeView().environmentObject(
        AppViewModel(context: context)
    )
}
