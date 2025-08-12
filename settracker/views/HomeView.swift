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
            .navigationDestination(isPresented: $viewModel.isCreatingTraining) {
                TrainingView(viewModel: viewModel)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Training Log")
                .font(.title2)
                .bold()

            Spacer()

            Button(action: {
                viewModel.isCreatingTraining = true
            }) {
                Label("New training", systemImage: "plus")
                    .font(.callout.bold())
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }.padding()
    }

    private var listView: some View {
        List {
            ForEach(
                groupTrainingsByWeek(viewModel.trainings),
                id: \.weekStart
            ) { group in
                Section(header: Text(formatWeekRange(group.weekStart))) {
                    ForEach(group.trainings) { training in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(training.type.rawValue)
                                    .font(.headline)
                                Spacer()
                                typeTag(for: training.type.rawValue)
                            }
                            Text(training.date.formatted())
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(Color.gray.opacity(0.05))
    }

    private func typeTag(for type: String) -> some View {
        Text(type)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.gray.opacity(0.3)))
    }
}

#Preview {
    HomeView(viewModel: AppViewModel())
}
