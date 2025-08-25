//
//  TrainingView.swift
//  settracker
//
//  Created by Nico Borsdorf on 28.07.25.
//

import SwiftData
import SwiftUI

struct TrainingView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    // UI state
    private var trainingId: String?
    @State private var selectedType: TrainingType?
    @State private var trainingExercises: [TrainingExercise] = []
    @State private var trainingDate: Date = Date()
    @State private var trainingDuration: Int = 0
    @State private var showPrevPicker = false
    @State private var selectedPrevTrainingId: String?
    @State private var showSetSheet = false
    @State private var editorExercise: TrainingExercise?  // for editing an existing exercise

    // MARK: - Init
    init(training: Training? = nil) {
        if let t = training {
            trainingId = t.id
            _selectedType = State(initialValue: t.type)
            _trainingDate = State(initialValue: t.date)
            _trainingExercises = State(initialValue: t.exercises)
            _trainingDuration = State(initialValue: t.duration)
        }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerCard
                    copyPreviousCard
                    exercisesCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(
                "Training - \(trainingDate.formatted(date: .numeric, time: .omitted))"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveTraining()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)
                    .accessibilityLabel(Text("save"))
                }
            }
            .sheet(
                item: $editorExercise,
                content: { exercise in
                    SetSheet(
                        appExercises: viewModel.exercises,
                        trainingExercise: exercise,
                        onCancel: { editorExercise = nil },
                        onSave: { updated in
                            if let idx = trainingExercises.firstIndex(where: {
                                $0.id == updated.id
                            }) {
                                trainingExercises[idx] = updated
                            } else {
                                trainingExercises.append(updated)
                            }
                            editorExercise = nil
                        }
                    )
                }
            )
            .sheet(isPresented: $showSetSheet) {
                SetSheet(
                    appExercises: viewModel.exercises,
                    trainingExercise: nil,
                    onCancel: { showSetSheet = false },
                    onSave: { newEx in
                        trainingExercises.append(newEx)
                        showSetSheet = false
                    }
                )
            }
        }
    }

    private var canSave: Bool {
        selectedType != nil && !trainingExercises.isEmpty
    }

    // MARK: - Cards

    private var headerCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("trainingType")
                        .font(.headline)
                    Spacer()
                    Picker("category", selection: $selectedType) {
                        Text("selectType").tag(nil as TrainingType?)
                        ForEach(TrainingType.allCases, id: \.rawValue) { t in
                            Text(t.rawValue.capitalized).tag(Optional(t))
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedType) { _, newValue in
                        if let t = newValue {
                            selectedType = t
                        }
                    }
                }
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { trainingDate },
                            set: { trainingDate = $0 }
                        ),
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                }
            }
        }
    }

    // MARK: Copy from previous card
    private var copyPreviousCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("copyFromPrev")
                            .font(.headline)
                        Text("reusePrevTraining")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button {
                        withAnimation(.easeInOut) { showPrevPicker.toggle() }
                    } label: {
                        Image(
                            systemName: showPrevPicker
                                ? "chevron.up" : "chevron.down"
                        )
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                    }
                    .accessibilityLabel(Text("togglePrevTrainings"))
                }

                if showPrevPicker {
                    VStack(alignment: .leading, spacing: 8) {
                        if viewModel.trainings.isEmpty {
                            Text("noPrevTrainings")
                                .foregroundColor(.gray)
                                .font(.caption)
                        } else {
                            Picker(
                                "prevTrainings",
                                selection: $selectedPrevTrainingId
                            ) {
                                Text("selectPrevTraining").tag(String?.none)
                                ForEach(
                                    viewModel.trainings
                                        .filter { !$0.exercises.isEmpty }
                                        .prefix(20)
                                ) { t in
                                    Text(
                                        "\(t.type.rawValue) | "
                                            + t.date.formatted(
                                                date: .numeric,
                                                time: .omitted
                                            )
                                    )
                                    .tag(String?(t.id))
                                }
                            }
                            .pickerStyle(.inline)
                        }
                        HStack {
                            Spacer()
                            Button {
                                if let id = selectedPrevTrainingId {
                                    copyFromTraining(id)
                                    withAnimation(.easeInOut) {
                                        showPrevPicker = false
                                    }
                                    selectedPrevTrainingId = nil
                                }
                            } label: {
                                Label("copy", systemImage: "doc.on.doc")
                            }
                            .disabled(selectedPrevTrainingId == nil)
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    // MARK: Exercise card
    private var exercisesCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(
                        String(
                            format: NSLocalizedString(
                                "exercises_nr",
                                comment: "\(trainingExercises.count)"
                            )
                        )
                    )
                    .font(.headline)
                    Spacer()
                    Button {
                        showSetSheet = true
                    } label: {
                        Label("addExercise", systemImage: "plus")
                    }
                    .disabled(viewModel.exercises.isEmpty)
                    .accessibilityIdentifier("addExerciseButton")
                }

                if trainingExercises.isEmpty {
                    Text("noExercises")
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                } else {
                    VStack(spacing: 10) {
                        ForEach(trainingExercises) { ex in
                            ExerciseRowView(
                                trainingExercise: ex,
                                onEdit: { editorExercise = $0 },
                                onDelete: {
                                    trainingExercises.removeAll {
                                        $0.id == ex.id
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func saveTraining() {
        guard let selectedType else { return }

        if let idx = viewModel.trainings.firstIndex(where: {
            $0.id == trainingId
        }) {
            var existing = viewModel.trainings[idx]
            existing.exercises = trainingExercises
            existing.date = trainingDate
            existing.duration = trainingDuration
            existing.type = selectedType
            viewModel.trainings[idx] = existing
        } else {
            let newTraining = Training(
                date: trainingDate,
                duration: trainingDuration,
                type: selectedType,
                exercises: trainingExercises
            )
            viewModel.trainings.append(newTraining)
        }
        dismiss()
    }

    private func copyFromTraining(_ trainingId: String) {
        guard
            let src = viewModel.trainings.first(where: { $0.id == trainingId })
        else { return }
        // Deep copy: duplicate exercises; if your TrainingExercise is a struct, this copies by value.
        // If you rely on unique IDs per exercise, you may want to generate new IDs here.
        let copied = src.exercises.map { ex in
            TrainingExercise(
                exercise: ex.exercise,
                category: ex.category,
                duration: ex.category == .cardio ? ex.duration : ex.duration,
                trainingSets: ex.trainingSets  // value-copied if struct
            )
        }
        trainingExercises.append(contentsOf: copied)
    }
}

// MARK: - Exercise Row
private struct ExerciseRowView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var trainingExercise: TrainingExercise
    var onEdit: (TrainingExercise) -> Void
    var onDelete: () -> Void

    @State private var showEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trainingExercise.exercise)
                        .font(.subheadline)
                    Text(summaryText(trainingExercise))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                HStack(spacing: 10) {
                    Button {
                        showEditor = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .sheet(isPresented: $showEditor) {
            SetSheet(
                appExercises: viewModel.exercises,
                trainingExercise: trainingExercise,
                onCancel: { showEditor = false },
                onSave: { updated in
                    onEdit(updated)
                }
            )
        }
    }

    private func summaryText(_ tEx: TrainingExercise) -> String {
        if tEx.category == .cardio {
            return "\(tEx.duration) min"
        }
        let sets = tEx.trainingSets
        guard !sets.isEmpty else { return "No sets configured" }
        let setCount = sets.count
        let sample = sets.prefix(3)
            .map { "\($0.reps)x\($0.weight.cleanWeight)" }
            .joined(separator: ", ")
        return "\(setCount) sets • \(sample)\(sets.count > 3 ? ", ..." : "")"
    }
}

// MARK: - Helpers
extension Double {
    fileprivate var cleanWeight: String {
        let intVal = Int(self)
        return Double(intVal) == self
            ? "\(intVal)kg" : String(format: "%.1fkg", self)
    }
}

#Preview {
    TrainingView().environmentObject(AppViewModel())
}
