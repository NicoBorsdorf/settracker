//
//  SetSheet.swift
//  settracker
//
//  A fresh, focused design for creating/editing a training exercise
//  - Choose an exercise
//  - Track time with a stopwatch
//  - Add, edit, delete sets
//

import SwiftUI

struct SetSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var viewModle: AppViewModel
    // Data sources and callbacks
    var onCancel: () -> Void
    var onSave: (TrainingExercise) -> Void

    // Editor state
    @Bindable var trainingExercise: TrainingExercise

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                // Info text
                infoText
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        exercisePickerCard
                        if trainingExercise.category == .cardio
                            || viewModle.settings.timeExercises
                        {
                            StopwatchCard(
                                stopwatchSeconds: $trainingExercise.duration
                            )
                        }
                        if trainingExercise.category != .cardio {
                            setsEditorCard
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                }
            }
            .background(Color(.systemGroupedBackground))
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
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle").font(.title2)
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel(Text("cancel"))
                } else {

                    Button(role: .cancel) {
                        onCancel()
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle").font(.title)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("cancel"))
                }

                Spacer()

                Text(trainingExercise.exercise)
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
                    TextField("exercise", text: $trainingExercise.exercise)
                        .foregroundColor(
                            trainingExercise.exercise.isEmpty
                                ? .secondary : .primary
                        )
                    Spacer()
                    Picker("category", selection: $trainingExercise.category) {
                        Text("selectCategory").tag(Category.none)
                        ForEach(
                            Category.allCases.filter { $0 != .none },
                            id: \.id
                        ) { cat in
                            Text(cat.id.capitalized).tag(cat)
                        }
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

                if trainingExercise.trainingSets.isEmpty {
                    Text("noSets")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach($trainingExercise.trainingSets, id: \.id) {
                            set in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Text("#\(set.wrappedValue.setId + 1)")
                                        .frame(width: 24, alignment: .leading)

                                    // Reps
                                    Stepper(value: set.reps, in: 1...100) {
                                        HStack(spacing: 4) {
                                            Text("reps").font(.caption2)
                                            Text("\(set.wrappedValue.reps)")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .fixedSize()

                                    Spacer()

                                    // Weight dropdown
                                    Menu {
                                        ForEach(weightOptions(), id: \.self) {
                                            w in
                                            Button {
                                                // Mutate the underlying value via wrappedValue
                                                set.weight.wrappedValue = w
                                            } label: {
                                                Text(weightText(w))
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "scalemass")
                                            Text(
                                                weightText(
                                                    set.wrappedValue.weight
                                                )
                                            )
                                        }
                                    }
                                    .fixedSize()
                                }
                            }
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                        .onDelete { offset in
                            withAnimation {
                                offset.forEach { idx in
                                    trainingExercise.trainingSets.remove(
                                        at: idx
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Rows
    private var canSave: Bool {
        return trainingExercise.category != .none
            && (trainingExercise.category != .cardio
                && !trainingExercise.trainingSets.isEmpty)
    }

    // MARK: - Actions
    private func addSet() {
        trainingExercise.trainingSets.append(
            TrainingSet(
                setId: Date().timeIntervalSince1970.hashValue,
                reps: 10,
                weight: 20
            )
        )
    }

    private func saveAndClose() {
        guard canSave else { return }

        onSave(trainingExercise)
        presentationMode.wrappedValue.dismiss()
    }

    // MARK: - Helpers
    private func weightOptions() -> [Double] {
        Array(stride(from: 0.0, through: 200.0, by: 2.5)).map { Double($0) }
    }

    private func weightText(_ w: Double) -> String {
        let int = Int(w)
        return Double(int) == w ? "\(int) kg" : String(format: "%.1f kg", w)
    }
}

#Preview {
    @Previewable @Environment(\.modelContext) var context
    let viewModel = AppViewModel(context: context)
    SetSheet(
        onCancel: {},
        onSave: { _ in },
        trainingExercise: TrainingExercise()
    )
    .environmentObject(viewModel)
}
