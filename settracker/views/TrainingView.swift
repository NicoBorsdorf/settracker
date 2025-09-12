//
//  TrainingView.swift
//  settracker
//
//  Created by Nico Borsdorf on 28.07.25.
//

import SwiftData
import SwiftUI

struct TrainingView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    // UI state
    @Bindable var training: Training
    @State private var showPrevPicker = false
    @State private var selectedPrevTrainingId: Int?
    @State private var editorExercise: TrainingExercise?  // for editing an existing exercise

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard
                if viewModel.settings.timeTrainings {
                    StopwatchCard(
                        stopwatchSeconds: $training.duration
                    )
                }
                copyPreviousCard
                exercisesCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(
            "Training - \(training.date.formatted(date: .numeric, time: .omitted))"
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
        .sheet(item: $editorExercise) { ex in
            SetSheet(
                onCancel: { editorExercise = nil },
                onSave: { newEx in
                    if newEx.isNew {
                        training.exercises.append(
                            TrainingExercise(
                                exercise: newEx.exercise,
                                category: newEx.category!,
                                duration: newEx.duration
                            )
                        )
                    }
                    editorExercise = nil
                },
                trainingExercise: Binding(
                    get: {
                        .init(
                            exercise: editorExercise!.exercise,
                            sets: editorExercise!.trainingSets,
                            category: editorExercise!.category,
                            duration: editorExercise!.duration,
                            isNew: false
                        )
                    },
                    set: {
                        editorExercise!.exercise = $0.exercise
                        editorExercise!.trainingSets = $0.sets
                        editorExercise!.category = $0.category!
                        editorExercise!.duration = $0.duration
                    }
                )
            )
        }
    }

    private var canSave: Bool {
        return training.type != .none && !training.exercises.isEmpty
    }

    // MARK: - Cards

    private var headerCard: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("trainingType")
                        .font(.headline)
                    Spacer()
                    Picker(
                        "category",
                        selection: $training.type
                    ) {
                        Text("selectType").tag(TrainingType.none)
                        ForEach(
                            TrainingType.allCases.filter { $0.self != .none },
                            id: \.rawValue
                        ) { t in
                            Text(LocalizedStringKey(t.rawValue)).tag(t)
                        }
                    }
                    .pickerStyle(.menu)
                }
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    DatePicker(
                        "",
                        selection: $training.date,
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
                                Text("selectPrevTraining").tag(nil as Int?)
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
                                    .tag(t.id.hashValue)
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
                                comment: "\(training.exercises.count)"
                            )
                        )
                    )
                    .font(.headline)
                    Spacer()
                    Button {
                        editorExercise = TrainingExercise()
                    } label: {
                        Label("addExercise", systemImage: "plus")
                    }
                    .accessibilityIdentifier("addExerciseButton")
                }

                if training.exercises.isEmpty == true {
                    Text("noExercises")
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                } else {
                    VStack(spacing: 10) {
                        ForEach($training.exercises) { ex in
                            ExerciseRowView(
                                trainingExercise: ex,
                                onEdit: { editorExercise = $0 },
                                onDelete: {
                                    training.exercises.removeAll {
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
        let exists = training.persistentBackingData.persistentModelID != nil

        if !exists {
            viewModel.addTraining(training)
        } else {
            viewModel.saveContext()
        }
        dismiss()
    }

    private func copyFromTraining(_ trainingId: Int) {
        guard
            let src = viewModel.trainings.first(where: {
                $0.id.hashValue == trainingId
            })
        else { return }
        // Deep copy: duplicate exercises; if your TrainingExercise is a struct, this copies by value.
        // If you rely on unique IDs per exercise, you may want to generate new IDs here.
        let copied = src.exercises.map { ex in
            TrainingExercise(
                exercise: ex.exercise,
                category: ex.category,
                duration: ex.duration,
                trainingSets: ex.trainingSets  // value-copied if struct
            )
        }
        training.exercises.append(contentsOf: copied)
    }
}

// MARK: - Exercise Row
private struct ExerciseRowView: View {
    @EnvironmentObject var viewModel: AppViewModel

    @Binding var trainingExercise: TrainingExercise
    var onEdit: (TrainingExercise) -> Void
    var onDelete: () -> Void

    @State private var editorExercise: TrainingExercise? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    if trainingExercise.duration > 0 {
                        Text(
                            "\(LocalizedStringResource(stringLiteral: trainingExercise.exercise)) -  \(trainingExercise.duration, specifier: "%.0f")"
                        )
                        .font(.subheadline)
                    } else {
                        Text(LocalizedStringKey(trainingExercise.exercise))
                            .font(.subheadline)
                    }
                    Text(summaryText(trainingExercise))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                HStack(spacing: 10) {
                    Button {
                        editorExercise = nil
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
        .sheet(item: $editorExercise) { editEx in
            SetSheet(
                onCancel: { editorExercise = nil },
                onSave: { ex in
                    trainingExercise.exercise = ex.exercise
                    trainingExercise.trainingSets = ex.sets
                    trainingExercise.category = ex.category!
                    trainingExercise.duration = ex.duration
                    editorExercise = nil
                },
                trainingExercise: Binding(
                    get: {
                        .init(
                            exercise: editEx.exercise,
                            sets: editEx.trainingSets,
                            category: editEx.category,
                            duration: editEx.duration,
                            isNew: false
                        )
                    },
                    set: {
                        editEx.exercise = $0.exercise
                        editEx.trainingSets = $0.sets
                        editEx.category = $0.category!
                        editEx.duration = $0.duration
                    }
                ),
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
    @Previewable @Environment(\.modelContext) var context
    @Previewable @State var training = Training(
        date: Date(),
        duration: 0,
        type: .none,
        exercises: []
    )

    TrainingView(
        training: training
    ).environmentObject(
        AppViewModel(context: context)
    )
}
