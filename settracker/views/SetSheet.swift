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
    var appExercises: [Exercise]
    var onCancel: () -> Void
    var onSave: (TrainingExercise) -> Void

    // Editor state
    @State private var category: Category?
    @State private var selectedExercise: Exercise?
    @State private var sets: [TrainingSet] = []

    // Stopwatch state
    @State private var stopwatchSeconds: Int = 0
    @State private var stopwatchRunning: Bool = false
    private let stopwatchTimer =
        Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: Init
    init(
        appExercises: [Exercise],
        trainingExercise: TrainingExercise?,
        onCancel: @escaping () -> Void,
        onSave: @escaping (TrainingExercise) -> Void
    ) {
        self.onCancel = onCancel
        self.onSave = onSave
        self.appExercises = appExercises

        if let t = trainingExercise {
            _category = State(initialValue: t.category)
            _selectedExercise = State(initialValue: appExercises.first(where: {$0.name.lowercased() == t.exercise.lowercased()}))
            _sets = State(initialValue: t.trainingSets)
            if t.category != .cardio {
                // optional: preload duration into stopwatch if you want
                _stopwatchSeconds = State(initialValue: max(0, t.duration * 60))
            }
        } else {
            _category = State(initialValue: nil)
            _selectedExercise = State(initialValue: nil)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            // Info text
            infoText

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    exercisePickerCard
                    stopwatchCard
                    if selectedExercise?.category != .cardio {
                        setsEditorCard
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(selectedExercise?.name.capitalized ?? "-")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.automatic)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) {
                    onCancel()
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.automatic)
                .accessibilityLabel(Text("cancel"))
            }

            ToolbarItem(placement: .confirmationAction) {
                if #available(iOS 26.0, *) {
                    Button(role: .confirm) {
                        saveAndClose()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)
                    .accessibilityLabel(Text("save"))
                } else {
                    Button {
                        saveAndClose()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)
                    .accessibilityLabel(Text("save"))
                }
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            HStack {
                if #available(iOS 26.0, *) {
                    Button(role: .cancel) {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark.circle").font(.title2)
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel(Text("cancel"))
                } else {
                    
                        Button(role: .cancel) {
                            onCancel()
                        } label: {
                            Image(systemName: "xmark.circle").font(.title)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("cancel"))
                }

                Spacer()

                Text(
                    selectedExercise?.category.rawValue.capitalized
                        ?? String(localized: "exercise")
                )
                .font(.headline)

                Spacer()

                if #available(iOS 26.0, *) {
                    Button(role: .confirm) {
                        saveAndClose()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title2)
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)
                    .accessibilityLabel(Text("save"))
                } else {
                    Button {
                        saveAndClose()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)
                    .accessibilityLabel(Text("save"))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
        }
    }

    // MARK: - Info
    private var infoText: some View {
        Text("infoText")
            .font(.footnote)
            .foregroundStyle(.gray)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.vertical, 8)
    }

    // MARK: - Sections
    private var exercisePickerCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("exercise").font(.headline)
                    Spacer()

                    Picker(
                        "exercise",
                        selection: Binding(
                            get: { selectedExercise },
                            set: { newValue in
                                selectedExercise = newValue
                                category = newValue?.category
                                if newValue?.category == .cardio {
                                    sets.removeAll()
                                }
                                // reset stopwatch state on exercise change
                                stopwatchRunning = false
                                stopwatchSeconds = 0
                            }
                        )
                    ) {
                        Text("selectExercise").tag(nil as Exercise?)
                        ForEach(appExercises) { e in
                            Text(e.name).tag(e as Exercise?)
                        }
                    }
                    .pickerStyle(.menu)
                }

                VStack(spacing: 8) {
                    // Category info
                    if let ex = selectedExercise {
                        HStack(spacing: 6) {
                            Image(systemName: "tag")
                                .foregroundColor(.secondary)
                            Text(
                                String(localized: "category")
                                    + ": \(ex.category.rawValue.capitalized)"

                            )
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
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
                    .buttonStyle(.borderedProminent)
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

                // Helper text
                if category == .cardio {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                        Text(
                            "cardioInfo"
                        )
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.secondary)
                        Text(
                            "savingTime"
                        )
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    private var setsEditorCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("sets").font(.headline)
                    Spacer()
                    Button {
                        addSet()
                    } label: {
                        Label("addSet", systemImage: "plus")
                    }
                }

                if sets.isEmpty {
                    Text("noSets")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    VStack(spacing: 10) {
                        // Use snapshot of indices to avoid mutation while iterating
                        ForEach(Array(sets.indices), id: \.self) { index in
                            setRow(index: index)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Rows
    private func setRow(index: Int) -> some View {
        let binding = Binding<TrainingSet>(
            get: { sets[index] },
            set: { sets[index] = $0 }
        )

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("#\(index + 1)")
                    .frame(width: 24, alignment: .leading)

                // Reps
                Stepper(value: binding.reps, in: 1...100) {
                    HStack(spacing: 4) {
                        Text("reps").font(.caption2)
                        Text("\(binding.reps.wrappedValue)")
                            .foregroundStyle(.secondary)
                    }
                }
                .fixedSize()

                Spacer()

                // Weight dropdown
                Menu {
                    ForEach(weightOptions(), id: \.self) { w in
                        Button {
                            binding.wrappedValue.weight = w
                        } label: {
                            Text(weightText(w))
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "scalemass")
                        Text(weightText(binding.wrappedValue.weight))
                    }
                }
                .fixedSize()

                Spacer()

                // Delete
                Button(role: .destructive) {
                    withAnimation(.easeInOut) {
                        sets.removeAll(where: { $0.id == binding.id })
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

    private var canSave: Bool {
        guard let selectedExercise else { return false }
        if selectedExercise.category == .cardio { return true }
        return !sets.isEmpty
    }

    // MARK: - Actions
    private func addSet() {
        sets.append(TrainingSet(id: sets.count, reps: 10, weight: 0))
    }

    private func saveAndClose() {
        guard let selectedExercise, let category else { return }
        var trEx = TrainingExercise(
            exercise: selectedExercise.name,
            category: category,
            trainingSets: sets
        )

        // Map stopwatch to minutes for non-cardio exercises
        if category != .cardio {
            trEx.duration = Int(round(Double(stopwatchSeconds) / 60.0))
        } else {
            // For cardio, store minutes either from stopwatch or leave 0
            trEx.duration = Int(round(Double(stopwatchSeconds) / 60.0))
        }

        onSave(trEx)
    }

    // MARK: - Helpers
    private func weightOptions() -> [Double] {
        Array(stride(from: 0.0, through: 200.0, by: 2.5)).map { Double($0) }
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
    SetSheet(
        appExercises: AppViewModel().exercises,
        trainingExercise: TrainingExercise(
            exercise: AppViewModel().exercises.first?.name
                ?? "Bench Press",
            category: .push,
            duration: 0,
            trainingSets: [TrainingSet(id: 0, reps: 10, weight: 40)]
        ),
        onCancel: {},
        onSave: { _ in }
    )
}
