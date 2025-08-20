//
//  HomeView.swift
//  settracker
//
//  Created by Nico Borsdorf on 28.07.25.
//
import SwiftData
import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            VStack {
                header
                listView
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }

    // MARK: header
    private var header: some View {
        HStack {
            Text("trainingLog")
                .font(.title2)
                .bold()

            Spacer()

            NavigationLink {
                TrainingView(viewModel: viewModel) // new training
            } label: {
                Label("newTraining", systemImage: "plus")
                    .font(.callout.bold())
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground).shadow(radius: 0.5))
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
                            TrainingView(training: training, viewModel: viewModel)
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
        .background(Color.gray.opacity(0.05))
    }

    // MARK: tag
    private func typeTag(for type: String) -> some View {
        let (color, text) = tagStyle(for: type)
        return Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(color.opacity(0.3)))
            .foregroundColor(color)
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

//#Preview {
//    HomeView(viewModel: AppViewModel())
//}
