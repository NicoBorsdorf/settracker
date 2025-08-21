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
    private var appExercises: [Exercise] = AppViewModel().exercises
    var onCancel: () -> Void
    var onSave: (TrainingExercise) -> Void

    // Editor state
    @State private var trainingExercise: TrainingExercise
    @State private var selectedExercise: Exercise?

    // Stopwatch state
    @State private var stopwatchSeconds: Int = 0
    @State private var stopwatchRunning: Bool = false
    private let stopwatchTimer = Timer.publish(every: 1, on: .main, in: .common)
        .autoconnect()

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
                    if selectedExercise?.category != Category.cardio {
                        setsEditorCard
                    }
                }
            }
            .navigationTitle("Sets")
        }
    }

    // MARK: Header
    private var header: some View {
        HStack {
            Button {
                onCancel()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .padding(6)
            }

            VStack(alignment: .leading) {
                Text("Sets")
                    .font(.headline)
                Text("addEditSet")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button {
                saveAndClose()
            } label: {
                Label("save", systemImage: "square.and.arrow.down")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(
                selectedExercise == nil
                    || (selectedExercise?.category != .cardio
                        && trainingExercise.trainingSets.isEmpty)
            )
            .opacity(
                (selectedExercise == nil
                    || (selectedExercise?.category != .cardio
                        && trainingExercise.trainingSets.isEmpty)
                    ? 0.6 : 1)
            )
        }
        .padding()
        .background(Color(.systemBackground).shadow(radius: 0.5))
        .onReceive(stopwatchTimer) { _ in
            if stopwatchRunning { stopwatchSeconds += 1 }
        }
    }

    // MARK: - Sections
    private var exercisePickerCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Spacer()
                    Text("exercise").font(.headline)
                    Spacer()
                }
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Picker("exercise", selection: $selectedExercise) {
                            Text("selectExercise").tag(nil as Exercise?)
                            ForEach(appExercises) { e in
                                Text(e.name).tag(e as Exercise?)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedExercise, initial: false) {
                            newValue,
                            _ in
                            trainingExercise.exercise = newValue
                            trainingExercise.category = newValue?.category
                            if newValue?.category == .cardio {
                                trainingExercise.trainingSets.removeAll()
                            }
                        }

                        if let ex = selectedExercise {
                            Text(
                                "category \(ex.category.rawValue.capitalized)"
                            )
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                    }

                    Spacer()
                }
            }
        }
    }

    private var stopwatchCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("stopwatch").font(.headline)
                    Spacer()
                    Button(stopwatchRunning ? "Stop" : "Start") {
                        stopwatchRunning.toggle()
                    }
                    .buttonStyle(stopwatchRunning ? .bordered : .bordered)
                    Button("reset") {
                        stopwatchRunning = false
                        stopwatchSeconds = 0
                    }
                    .disabled(stopwatchSeconds == 0 && !stopwatchRunning)
                }
                Text(formattedTime(stopwatchSeconds))
                    .font(
                        .system(
                            size: 36,
                            weight: .semibold,
                            design: .monospaced
                        )
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                if trainingExercise.category == .cardio {
                    // For cardio: expose duration as minutes control
                    Stepper(
                        value: $trainingExercise.duration,
                        in: 5...180,
                        step: 5
                    ) {
                        HStack {
                            Text("targetDuration")
                            Spacer()
                            Text("\(trainingExercise.duration) min")
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("savingTime")
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
                        Label("addSet", systemImage: "plus")
                    }
                }

                if trainingExercise.category == .cardio {
                    Text("cardioNoSet")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else if trainingExercise.trainingSets.isEmpty {
                    Text("noSets")
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
            HStack(alignment: .center, spacing: 4) {
                Text("#\((indexForSet(id: set.wrappedValue.id) ?? 0) + 1)")
                    .frame(width: 20, alignment: .leading)
                Spacer()
                Stepper(
                    value: set.reps,
                    in: 1...100
                ) {
                    Text("reps").font(.caption2)
                    Text("\(set.wrappedValue.reps)")
                        .foregroundColor(.secondary)
                        .font(.subheadline).multilineTextAlignment(.center)

                }.fixedSize()

                Spacer()
                Menu {
                    ForEach(weightOptions(), id: \.self) { w in
                        Button {
                            set.wrappedValue.weight = w
                        } label: {
                            Text(weightText(w))
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "scalemass")
                        Text(
                            weightText(
                                set.wrappedValue.weight
                            )
                        )
                    }
                }.fixedSize()

                Spacer()

                Button(role: .destructive) {
                    trainingExercise.trainingSets.removeAll {
                        $0.id == set.wrappedValue.id
                    }
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("deleteSet")
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
            trainingExercise.duration = Int(
                round(Double(stopwatchSeconds) / 60.0)
            )
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

    private func weightOptions() -> [Double] {
        return stride(from: 0.0, through: 200.0, by: 2.5).map { Double($0) }
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

