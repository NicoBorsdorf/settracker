//
//  SetSheet.swift
//  settracker
//
//  A fresh, focused design for creating/editing a training exercise
//  - Choose an exercise
//  - Track time with a stopwatch
//  - Add, edit, delete sets
//

import SwiftData
import SwiftUI

struct SetSheet: View {
    // Data sources and callbacks
    var appExercises: [Exercise] = AppViewModel().exercises
    var onCancel: () -> Void
    var onSave: (TrainingExercise) -> Void

    // Editor state
    @State private var trainingExercise: TrainingExercise
    @State private var selectedExercise: Exercise?

    // Stopwatch state
    @State private var stopwatchSeconds: Int = 0
    @State private var stopwatchRunning: Bool = false
    private let stopwatchTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(
        trainingExercise: TrainingExercise?,
        onCancel: @escaping () -> Void,
        onSave: @escaping (TrainingExercise) -> Void
    ) {
        self.onCancel = onCancel
        self.onSave = onSave

        if let t = trainingExercise {
            _trainingExercise = State(initialValue: t)
            _selectedExercise = State(initialValue: t.exercise)
        } else {
            _trainingExercise = State(initialValue: TrainingExercise())
            _selectedExercise = State(initialValue: nil)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    exercisePickerCard
                    stopwatchCard
                    setsEditorCard
                }
                .padding()
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndClose() }
                        .disabled(selectedExercise == nil || (
                            selectedExercise?.category != .cardio && trainingExercise.trainingSets.isEmpty
                        ))
                }
            }
            .onReceive(stopwatchTimer) { _ in
                if stopwatchRunning { stopwatchSeconds += 1 }
            }
        }
    }

    // MARK: - Sections
    private var exercisePickerCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Exercise").font(.headline)
                Picker("Exercise", selection: $selectedExercise) {
                    Text("Select exercise...").tag(nil as Exercise?)
                    ForEach(appExercises) { e in
                        Text(e.name).tag(e as Exercise?)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedExercise) { newValue in
                    trainingExercise.exercise = newValue
                    trainingExercise.category = newValue?.category
                    if newValue?.category == .cardio {
                        trainingExercise.trainingSets.removeAll()
                    }
                }

                if let ex = selectedExercise {
                    Text("Category: \(ex.category.rawValue.capitalized)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }

    private var stopwatchCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Stopwatch").font(.headline)
                    Spacer()
                    Button(stopwatchRunning ? "Stop" : "Start") {
                        stopwatchRunning.toggle()
                    }
                    .buttonStyle(stopwatchRunning ? .borderedProminent : .bordered)
                    Button("Reset") {
                        stopwatchRunning = false
                        stopwatchSeconds = 0
                    }
                    .disabled(stopwatchSeconds == 0 && !stopwatchRunning)
                }
                Text(formattedTime(stopwatchSeconds))
                    .font(.system(size: 36, weight: .semibold, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if trainingExercise.category == .cardio {
                    // For cardio: expose duration as minutes control
                    Stepper(value: $trainingExercise.duration, in: 5...180, step: 5) {
                        HStack {
                            Text("Target Duration")
                            Spacer()
                            Text("\(trainingExercise.duration) min").foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("When saving, time is added as minutes to the exercise.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }

    private var setsEditorCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Sets").font(.headline)
                    Spacer()
                    Button {
                        addSet()
                    } label: {
                        Label("Add set", systemImage: "plus")
                    }
                }

                if trainingExercise.category == .cardio {
                    Text("Cardio exercises do not use sets.")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else if trainingExercise.trainingSets.isEmpty {
                    Text("No sets yet. Tap ‘Add set’.")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    VStack(spacing: 10) {
                        ForEach($trainingExercise.trainingSets) { $set in
                            setRow($set)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Rows
    private func setRow(_ set: Binding<TrainingSet>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                Text("#\((indexForSet(id: set.wrappedValue.id) ?? 0) + 1)")
                    .frame(width: 28, alignment: .leading)

                // Reps
                Stepper(value: set.reps, in: 1...100) {
                    HStack {
                        Text("Reps")
                        Spacer()
                        Text("\(set.wrappedValue.reps)")
                            .foregroundColor(.secondary)
                    }
                }

                // Weight
                Stepper(value: set.weight, in: 0...250, step: 2.5) {
                    HStack {
                        Image(systemName: "scalemass")
                        Text(weightText(set.wrappedValue.weight))
                    }
                }

                Spacer()

                Button(role: .destructive) {
                    trainingExercise.trainingSets.removeAll { $0.id == set.wrappedValue.id }
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete set")
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - Actions
    private func addSet() {
        trainingExercise.trainingSets.append(TrainingSet(reps: 10, weight: 0))
    }

    private func saveAndClose() {
        trainingExercise.exercise = selectedExercise
        trainingExercise.category = selectedExercise?.category

        // Map stopwatch to minutes for non-cardio exercises
        if trainingExercise.category != .cardio {
            trainingExercise.duration = Int(round(Double(stopwatchSeconds) / 60.0))
        }

        onSave(trainingExercise)
    }

    // MARK: - Helpers
    private func indexForSet(id: String) -> Int? {
        trainingExercise.trainingSets.firstIndex { $0.id == id }
    }

    private func weightText(_ w: Double) -> String {
        let int = Int(w)
        return Double(int) == w ? "\(int) kg" : String(format: "%.1f kg", w)
    }

    private func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

#Preview {
    NavigationStack {
        SetSheet(
            trainingExercise: TrainingExercise(
                exercise: AppViewModel().exercises.first,
                category: .push,
                duration: 0,
                trainingSets: [TrainingSet(reps: 8, weight: 50)]
            ),
            onCancel: {},
            onSave: { _ in }
        )
    }
}
