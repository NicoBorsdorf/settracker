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
        trainingExercise: TrainingExercise?,
        onCancel: @escaping () -> Void,
        onSave: @escaping (TrainingExercise) -> Void
    ) {
        self.onCancel = onCancel
        self.onSave = onSave
        if let t = trainingExercise {
            _trainingExercise = State(initialValue: t)
            _exercise = State(initialValue: t.exercise)
        } else {
            _trainingExercise = State(initialValue: TrainingExercise())
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Exercise", selection: $exercise) {
                        Text("Select exercise...").tag(nil as Exercise?)
                        ForEach(appExercises) { e in
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
                                if trainingExercise.trainingSets.isEmpty {
                                    Text("No sets. Add one.")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                Spacer()
                                Button {
                                    addSet()
                                } label: {
                                    Image(systemName: "plus")
                                }
                                .buttonStyle(.bordered)
                            }

                            ForEach(Array(trainingExercise.trainingSets.indices), id: \.self) { index in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("#\(index + 1)")
                                        .frame(width: 32, alignment: .leading)

                                    HStack(spacing: 12) {
                                        Stepper(
                                            value: $trainingExercise.trainingSets[index].reps,
                                            in: 1...100
                                        ) {
                                            HStack {
                                                Text("Reps")
                                                Spacer()
                                                Text("\(trainingExercise.trainingSets[index].reps)")
                                                    .foregroundColor(.secondary)
                                            }
                                        }

                                        Menu {
                                            ForEach(weightOptions(), id: \.self) { w in
                                                Button {
                                                    trainingExercise.trainingSets[index].weight = w
                                                } label: {
                                                    Text(weightText(w))
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: "scalemass")
                                                Text(weightText(trainingExercise.trainingSets[index].weight))
                                            }
                                        }

                                        Spacer()

                                        Button(role: .destructive) {
                                            trainingExercise.trainingSets.remove(at: index)
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
