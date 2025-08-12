//
//  TrainingView.swift
//  settracker
//
//  Created by Nico Borsdorf on 28.07.25.
//

import SwiftData
import SwiftUI

struct TrainingView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss
    @State private var training: Training

    init(training: Training? = nil, viewModel: AppViewModel) {
        if let t = training {
            _training = State(initialValue: t)
        } else {
            _training = State(
                initialValue: .init(
                    date: Date(),
                    duration: 0,
                    type: TrainingType.strength,
                    exercises: []
                )
            )
        }
        self.viewModel = viewModel
    }

    @State private var type = ""
    @State private var showTrainings = false
    @State private var prevTraining: String? = nil

    // Sheet state for add exercise
    @State private var showSetSheet = false

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 20) {
                    trainingDetails
                    copyFromPrevious
                    exerciseSection
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showSetSheet) {
            SetSheet(
                trainingExercise: TrainingExercise(exercise: viewModel.exercises[0], category: Category.pull, duration: 0),
                onCancel: { showSetSheet = false },
                onSave: { set in
                    training.exercises.append(set)
                    showSetSheet = false
                }
            )
        }
    }

    private var header: some View {
        // MARK: Header
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .padding(6)
            }

            VStack(alignment: .leading) {
                Text("New Training")
                    .font(.headline)
                Text("Create your workout")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            Button {
                saveTraining()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(type.isEmpty || training.exercises.isEmpty)
            .opacity(type.isEmpty || training.exercises.isEmpty ? 0.6 : 1)
        }
        .padding()
        .background(Color(.systemBackground).shadow(radius: 0.5))
    }

    private var trainingDetails: some View {
        // MARK: Training Details
        SectionCard {
            HStack(alignment: .center) {
                Text("Training Type").font(.headline)
                Spacer()
                Picker("Category", selection: $type) {
                    Text("Select type").tag("")
                    Text("Push").tag("Push")
                    Text("Pull").tag("Pull")
                    Text("Legs").tag("Legs")
                    Text("Cardio").tag("Cardio")
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var copyFromPrevious: some View {
        // MARK: Copy from Previous
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Copy from previous")
                            .font(.headline)
                        Text("Reuse a recent training as a template")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button {
                        withAnimation(.easeInOut) {
                            showTrainings.toggle()
                        }
                    } label: {
                        Image(
                            systemName: showTrainings
                                ? "chevron.up"
                                : "chevron.down"
                        )
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(Circle())
                    }
                    .accessibilityLabel("Toggle previous trainings")
                }

                if showTrainings {
                    VStack(alignment: .leading, spacing: 8) {
                        if viewModel.trainings.isEmpty {
                            Text("No previous trainings available")
                                .foregroundColor(.gray)
                                .font(.caption)
                        } else {
                            Picker(
                                "Previous trainings",
                                selection: $prevTraining
                            ) {
                                Text("Select previous training").tag(
                                    String?.none
                                )
                                ForEach(
                                    viewModel.trainings
                                        .filter { !$0.exercises.isEmpty }
                                        .prefix(10)
                                ) { t in
                                    Text(
                                        "\(t.type) | "
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
                                if let id = prevTraining {
                                    copyFromTraining(id)
                                    withAnimation(.easeInOut) {
                                        showTrainings = false
                                    }
                                    prevTraining = nil
                                }
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .disabled(prevTraining == nil)
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var exerciseSection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Exercises (\(training.exercises.count))")
                        .font(.headline)
                    Spacer()
                    Button {
                        // Open browser of exercises
                        // We'll show a categorized inline list below as well
                    } label: {
                        Label("Add exercise", systemImage: "plus")
                    }

                    .disabled(viewModel.exercises.isEmpty)
                }

                if training.exercises.isEmpty {
                    Text("No exercises added yet")
                        .foregroundColor(.gray)
                        .padding(.bottom, 8)
                } else {
                    VStack(spacing: 10) {
                        ForEach(training.exercises) { ex in
                            ExerciseRow(
                                trainingExercise: ex,
                                onDelete: {
                                    training.exercises.removeAll {
                                        $0.id == ex.id
                                    }
                                },
                                onEdit: { updated in
                                    if let idx = training.exercises.firstIndex(
                                        where: { $0.id == updated.id }
                                    ) {
                                        training.exercises[idx] = updated
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helper Views & Methods
    func saveTraining() {
        guard !type.isEmpty, !training.exercises.isEmpty else {
            return
        }

        viewModel.trainings.append(training)
        dismiss()
    }

    func copyFromTraining(_ trainingId: String) {
        // Deep copy exercises with new IDs and duplicated sets
        let copied: [TrainingExercise] = training.exercises.map { src in
            let copiedSets = src.trainingSets.map { set in
                TrainingSet(
                    reps: set.reps,
                    weight: set.weight
                )
            }
            return TrainingExercise(
                exercise: src.exercise,
                category: src.category,
                duration: src.duration,
                trainingSets: copiedSets
            )
        }

        training.exercises.append(contentsOf: copied)
    }
}

// Per-exercise row with quick overview and delete, edit hooks
private struct ExerciseRow: View {
    var trainingExercise: TrainingExercise
    var onDelete: () -> Void
    var onEdit: (TrainingExercise) -> Void

    @State private var showEditor = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading) {
                    Text(trainingExercise.exercise.name).font(.subheadline)
                    Text(summaryText(trainingExercise))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
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
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .sheet(isPresented: $showEditor) {
            SetSheet(
                trainingExercise: trainingExercise,
                onCancel: { showEditor = false },
                onSave: { updated in
                    onEdit(updated)
                    showEditor = false
                }
            )
        }
    }

    private func summaryText(_ ex: TrainingExercise) -> String {
        if ex.exercise.category == Category.cardio {
            return "\(ex.duration) min"
        }
        let sets = ex.trainingSets
        let setCount = sets.count
        let repSamples = sets.prefix(3).map {
            "\($0.reps)x\(($0.weight).cleanWeight)"
        }
        .joined(separator: ", ")
        return
            "\(setCount) sets • \(repSamples)\(sets.count > 3 ? ", ..." : "")"

    }
}

extension Double {
    fileprivate var cleanWeight: String {
        let int = Int(self)
        return Double(int) == self ? "\(int)kg" : String(format: "%.1fkg", self)
    }
}

struct SectionCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack {
                content
            }.frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        .frame(maxWidth: .infinity)

    }
}

#Preview {
    TrainingView(viewModel: AppViewModel())
}
