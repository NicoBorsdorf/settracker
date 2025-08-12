//
//  EditExerciseSheet.swift
//  settracker
//
//  Created by Nico Borsdorf on 06.08.25.
//

import SwiftData
import SwiftUI

struct SetSheet: View {
    var appExercises: [Exercise] = AppViewModel().exercises
    var onCancel: () -> Void
    var onSave: (TrainingExercise) -> Void

    @State private var trainingExercise: TrainingExercise
    @State private var exercise: Exercise? = nil

    init(
        trainingExercise: TrainingExercise,
        onCancel: @escaping () -> Void,
        onSave: @escaping (TrainingExercise) -> Void
    ) {
        self.onCancel = onCancel
        self.onSave = onSave
        _trainingExercise = State(initialValue: trainingExercise)
        _exercise = State(initialValue: trainingExercise.exercise)  
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Exercise", selection: $exercise) {
                        ForEach(appExercises){e in
                            Text(e.name).tag(e)
                        }
                    }
                    .pickerStyle(.automatic)
                }
                Section {
                    if exercise?.category == Category.cardio {
                        Stepper(
                            value: $trainingExercise.duration,
                            in: 5...180,
                            step: 5
                        ) {
                            HStack {
                                Text("Duration")
                                Spacer()
                                Text("\(String(trainingExercise.duration)) min")
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Spacer()
                                Button {
                                    addSet()
                                } label: {
                                    Image(systemName: "plus")
                                }
                                .buttonStyle(.bordered)
                            }
                            if trainingExercise.trainingSets.isEmpty {
                                Text("No sets. Add one.")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            } else {
                                ForEach(
                                    trainingExercise.trainingSets.indices,
                                    id: \.self
                                ) { index in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("#\(String(index + 1))")
                                            .frame(
                                                width: 32,
                                                alignment: .leading
                                            )
                                        HStack(spacing: 12) {

                                            Stepper(
                                                value: binding(for: index).reps,
                                                in: 1...100
                                            ) {
                                                HStack {
                                                    Text("Reps")
                                                    Spacer()
                                                    Text(
                                                        "\(String(binding(for: index).reps.wrappedValue))"
                                                    )
                                                    .foregroundColor(.secondary)
                                                }
                                            }
                                            Menu {
                                                ForEach(
                                                    weightOptions(),
                                                    id: \.self
                                                ) { w in
                                                    Button {
                                                        setWeight(w, for: index)
                                                    } label: {
                                                        Text(weightText(w))
                                                    }
                                                }
                                            } label: {
                                                HStack {
                                                    Image(
                                                        systemName: "scalemass"
                                                    )
                                                    Text(
                                                        weightText(
                                                            binding(for: index)
                                                                .weight
                                                                .wrappedValue
                                                        )
                                                    )
                                                }
                                            }

                                            Spacer()

                                            Button(role: .destructive) {
                                                let _ = trainingExercise.trainingSets
                                                    .remove(at: index)
                                            } label: {
                                                Image(systemName: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

            }
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(trainingExercise) }
                }
            }
        }
    }

    private func addSet() {
        var sets = trainingExercise.trainingSets
        sets.append(TrainingSet(reps: 10, weight: 0))
        trainingExercise.trainingSets = sets
    }

    private func binding(for i: Int) -> Binding<TrainingSet> {
        Binding<TrainingSet>(
            get: {
                return trainingExercise.trainingSets[i]
            },
            set: { newVal in
                var sets = trainingExercise.trainingSets
                sets[i] = newVal
                trainingExercise.trainingSets = sets
            }
        )
    }

    private func setWeight(_ weight: Double, for i: Int) {
        var sets = trainingExercise.trainingSets
        sets[i].weight = weight
        trainingExercise.trainingSets = sets
    }

    private func weightOptions() -> [Double] {
        return stride(from: 0.0, through: 200.0, by: 2.5).map { Double($0) }
    }

    private func weightText(_ w: Double) -> String {
        let int = Int(w)
        return Double(int) == w ? "\(int) kg" : String(format: "%.1f kg", w)
    }
}

#Preview {
    SetSheet(
        trainingExercise: TrainingExercise(
            exercise: AppViewModel().exercises[0],
            category: Category.push,
            duration: 0,
            trainingSets: []
        ),
        onCancel: {},
        onSave: { t in print(t) }
    )
}
