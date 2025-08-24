//
//  HomeView.swift
//  settracker
//
//  Created by Nico Borsdorf on 28.07.25.
//
import SwiftData
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
            NavigationStack {
                VStack {
                   listView
                }
                .navigationTitle("trainingLog")
                .toolbar{
                    NavigationLink(destination: TrainingView(), label: {
                        Label("", systemImage: "plus")
                    })
                }
            }
    }

    // MARK: list
    private var listView: some View {
        List {
            ForEach(
                groupTrainingsByWeek(viewModel.trainings),
                id: \.weekStart
            ) { group in
                Section(header: Text(formatWeekRange(group.weekStart))) {
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
                                typeTag(for: training.type.rawValue)
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
    private func typeTag(for type: String) -> some View {
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

    private func tagStyle(for type: String) -> (Color, String) {
        switch type.lowercased() {
        case "strength":
            return (.red, "strength")
        case "cardio":
            return (.green, "cardio")
        case "mobility":
            return (.orange, "mobility")
        default:
            return (.gray, type.capitalized)
        }
    }
}

#Preview {
    HomeView()
}
