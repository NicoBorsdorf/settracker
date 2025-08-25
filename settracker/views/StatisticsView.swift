//
//  StatisticsView.swift
//  settracker
//
//  Created by Nico Borsdorf on 24.08.25.
//

import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var viewModel: AppViewModel

    // MARK: - Computed Stats
    private var trainings: [Training] { viewModel.trainings }

    private var averagePerWeek: Double {
        guard let first = trainings.map(\.date).min(),
              let last = trainings.map(\.date).max(),
              !trainings.isEmpty else { return 0 }

        let weeks = max(1, Calendar.current.dateComponents([.weekOfYear], from: first, to: last).weekOfYear ?? 1)
        return Double(trainings.count) / Double(weeks)
    }

    private var typeDistribution: [(String, Double)] {
        let total = Double(trainings.count)
        guard total > 0 else { return [] }

        let grouped = Dictionary(grouping: trainings, by: { $0.type })
        return grouped.map { (type, items) in
            (type.rawValue.capitalized, Double(items.count) / total * 100)
        }
    }

    private var splitDistribution: [(String, Double)] {
        let allExercises = trainings.flatMap { $0.exercises }
        let total = Double(allExercises.count)
        guard total > 0 else { return [] }

        let grouped = Dictionary(grouping: allExercises, by: { $0.category })
        return grouped.map { (cat, items) in
            (cat.rawValue.capitalized, Double(items.count) / total * 100)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Average trainings per week
                    SectionCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("avgTrainings")
                                .font(.headline)
                            Text(String(format: "%.1f", averagePerWeek))
                                .font(.largeTitle.bold())
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Training type distribution
                    SectionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("trainingTypes")
                                .font(.headline)

                            if typeDistribution.isEmpty {
                                Text("noData")
                                    .foregroundColor(.gray)
                            } else {
                                Chart(typeDistribution, id: \.0) { item in
                                    SectorMark(
                                        angle: .value("Percentage", item.1),
                                        innerRadius: .ratio(0.5),
                                        angularInset: 1
                                    )
                                    .foregroundStyle(colorForType(item.0))
                                    .annotation(position: .overlay) {
                                        Text("\(item.0)\n\(String(format: "%.0f%%", item.1))")
                                            .font(.caption2)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(height: 250)
                            }
                        }
                    }

                    // Split distribution
                    SectionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("splits")
                                .font(.headline)

                            if splitDistribution.isEmpty {
                                Text("noData")
                                    .foregroundColor(.gray)
                            } else {
                                Chart(splitDistribution, id: \.0) { item in
                                    SectorMark(
                                        angle: .value("Percentage", item.1),
                                        innerRadius: .ratio(0.5),
                                        angularInset: 1
                                    )
                                    .foregroundStyle(colorForSplit(item.0))
                                    .annotation(position: .overlay) {
                                        Text("\(item.0)\n\(String(format: "%.0f%%", item.1))")
                                            .font(.caption2)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(height: 250)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("statistics")
        }
    }

    // MARK: - Helpers
    private func colorForType(_ type: String) -> Color {
        switch type.lowercased() {
        case "strength": return .red
        case "cardio": return .green
        case "mobility": return .orange
        default: return .gray
        }
    }

    private func colorForSplit(_ split: String) -> Color {
        switch split.lowercased() {
        case "push": return .blue
        case "pull": return .purple
        case "legs": return .pink
        case "cardio": return .green
        default: return .gray
        }
    }
}

#Preview {
    StatisticsView().environmentObject(AppViewModel())
}
