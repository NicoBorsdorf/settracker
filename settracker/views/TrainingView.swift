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
            _type = State(initialValue: t.type)
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

    @State private var type: TrainingType? = nil
    @State private var showTrainings = false
    @State private var prevTraining: String? = nil

    // Sheet state for add exercise
    @State private var showSetSheet = false

    var body: some View {
      NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    trainingDetails
                    copyFromPrevious
                    exerciseSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Training - \(training.date.formatted(date: .numeric, time: .omitted))")
            .toolbar{
                if #available(iOS 26.0, *){
                    ToolbarItem(placement: .confirmationAction){
                        Button("",systemImage: "square.and.arrow.down", role: .confirm){
                            saveTraining()
                        }
                        .disabled(type == nil || training.exercises.isEmpty)
                        .opacity(type == nil || training.exercises.isEmpty ? 0.6 : 1)
                    }
                } else {
                    ToolbarItem(placement: .confirmationAction){
                        Button{
                            saveTraining()
                        } label: {
                            Label("Save", systemImage: "square.and.arrow.down")
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(type == nil || training.exercises.isEmpty)
                        .opacity(type == nil || training.exercises.isEmpty ? 0.6 : 1)
                    }
                }
            }
            //.navigationSubtitle("createWorkout")
      }
    }

  
    // MARK: Training Details
    private var trainingDetails: some View {
        SectionCard {
            HStack(alignment: .center) {
                Text("trainingType").font(.headline)
                Spacer()
                Picker("category", selection: $type) {
                    Text("selectType").tag(nil as TrainingType?)
                    ForEach(TrainingType.allCases, id: \.rawValue) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.menu)
            }
        }
    }
    
    // MARK: Copy from Previous
    private var copyFromPrevious: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("copyFromPrev")
                            .font(.headline)
                        Text("reusePrevTraining")
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
                    .accessibilityLabel("togglePrevTrainings")
                }

                if showTrainings {
                    VStack(alignment: .leading, spacing: 8) {
                        if viewModel.trainings.isEmpty {
                            Text("noPrevTrainings")
                                .foregroundColor(.gray)
                                .font(.caption)
                        } else {
                            Picker(
                                "prevTrainings",
                                selection: $prevTraining
                            ) {
                                Text("selectPrevTraining").tag(
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
                                Label("copy", systemImage: "doc.on.doc")
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

    // MARK: - Exercise section
    private var exerciseSection: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(LocalizedStringKey("exercises \(training.exercises.count)"))
                        .font(.headline)
                    Spacer()
                    Button {
                        showSetSheet = true
                    } label: {
                        Label("addExercise", systemImage: "plus")
                    }
                    .disabled(viewModel.exercises.isEmpty)
                    .sheet(isPresented: $showSetSheet) {
                        SetSheet(
                            trainingExercise: nil,
                            onCancel: {
                                showSetSheet = false
                            },
                            onSave: { t in
                                training.exercises.append(t)
                                showSetSheet = false
                            }
                        )

                    }
                }

                if training.exercises.isEmpty {
                    Text("noExercises")
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
        guard let selectedType = type, !training.exercises.isEmpty else {
            return
        }
        if let idxExisting = viewModel.trainings.firstIndex(where: { $0.id == training.id }) {
            viewModel.trainings[idxExisting] = training
            dismiss()
            return
        }
        let newTraining = Training(
            date: training.date,
            duration: training.duration,
            type: selectedType,
            exercises: training.exercises
        )
        viewModel.trainings.append(newTraining)
        dismiss()
    }

    func copyFromTraining(_ trainingId: String) {
        guard let toCopy = viewModel.trainings.first(where: { $0.id == trainingId }) else { return }
        // Deep copy exercises with new IDs and duplicated sets
        let copied: [TrainingExercise] = toCopy.exercises.map { src in
            return TrainingExercise(
                exercise: src.exercise,
                category: src.category,
                duration: src.duration,
                trainingSets: src.trainingSets
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
                    Text(trainingExercise.exercise?.name ?? "noEcerise").font(
                        .subheadline
                    )
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

    private func summaryText(_ tEx: TrainingExercise) -> String {
        if let ex = tEx.exercise, ex.category == Category.cardio {
            return "\(tEx.duration) min"
        }
        let sets = tEx.trainingSets
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

