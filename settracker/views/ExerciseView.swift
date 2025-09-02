//
//  ExersiceView.swift
//  settracker
//
//  Created by Nico Borsdorf on 28.07.25.
//

import SwiftData
import SwiftUI

struct ExerciseLibraryView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var editingCategory: Category? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(Category.allCases, id: \.self) { category in
                        let exercises = viewModel.exercises.filter {
                            $0.category == category
                        }

                        SectionCard {
                            VStack(alignment: .leading, spacing: 10) {
                                // Header row
                                HStack {
                                    Text(category.rawValue.uppercased())
                                        .font(.headline)
                                    Spacer()
                                    Button {
                                        editingCategory = category
                                    } label: {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.blue)
                                    }
                                }

                                if exercises.isEmpty {
                                    Text("noExercises")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.vertical, 4)
                                } else {
                                    VStack(spacing: 8) {
                                        ForEach(exercises) { exercise in
                                            HStack {
                                                Text(exercise.name)
                                                    .font(.subheadline)
                                                Spacer()
                                            }
                                            .padding(10)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("exerciseLibrary")
            .sheet(item: $editingCategory) { category in
                let exercises = viewModel.exercises.filter {
                    $0.category == category
                }
                ExerciseSheet(
                    viewModel: viewModel,
                    category: category,
                    exercises: Binding<[Exercise]>(
                        get: { exercises },
                        set: { _ in }
                    ),
                    onClose: { editingCategory = nil }
                )
            }
        }
    }
}

// MARK: - Exercise Row
private struct ExerciseRow: View {
    @Environment(\.colorScheme) var colorScheme
    var exerciseName: Binding<String>

    var body: some View {
        HStack {
            TextField("", text: exerciseName)
                .font(.subheadline)
            Spacer()
        }
        .padding(10)
        .background(colorScheme == .dark ? Color(.white) : Color(.systemGray))
        .cornerRadius(8)
    }
}

// MARK: - Category Exercise Sheet
struct ExerciseSheet: View {
    var viewModel: AppViewModel
    var category: Category
    @Binding var exercises: [Exercise]  // full exercise list
    var onClose: () -> Void

    @State private var newExerciseName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 4)

            // Header
            HStack {
                Text(category.rawValue.capitalized)
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            // Info text
            Text("exerciseSheetInfo")
                .font(.footnote)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 8)

            Divider()

            // List of exercises
            let defaultEx = exercises.filter {
                $0.isDefault
            }
            let nonDefaultEx = exercises.filter {
                !$0.isDefault
            }
            List {
                ForEach(defaultEx, id: \.self) { ex in
                    HStack {
                        Text(ex.name.capitalized)
                            .textFieldStyle(.plain)
                        Spacer()
                    }
                }
                ForEach(nonDefaultEx, id: \.self) { ex in
                    HStack {
                        TextField(
                            "exerciseName",
                            text: bindingForExercise(ex)
                        )
                        .textFieldStyle(.plain)
                        Spacer()
                        Button(role: .destructive) {
                            exercises.removeAll { $0.id == ex.id }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                .onDelete(perform: deleteExerciseAtOffsets)

                // Add new exercise row
                HStack {
                    TextField("exerciseName", text: $newExerciseName)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        addExercise()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(
                                newExerciseName.isEmpty ? .gray : .blue
                            )
                    }
                    .disabled(newExerciseName.isEmpty)
                }
            }
            .listStyle(.insetGrouped)
        }
        .presentationDetents([.medium, .large])  // nice sheet sizes
    }

    // MARK: - Helpers

    private func bindingForExercise(_ ex: Exercise) -> Binding<String> {
        Binding<String>(
            get: { ex.name },
            set: { newValue in
                ex.name = newValue
            }
        )
    }

    private func addExercise() {
        let newExercise = Exercise(
            name: newExerciseName,
            category: category
        )
        exercises.append(newExercise)
        viewModel.addExercise(newExercise)
        newExerciseName = ""
    }

    private func deleteExercise(at idx: Int) {
        exercises.remove(at: idx)
        viewModel.deleteExercise(exercises[idx])
    }

    private func deleteExerciseAtOffsets(_ offsets: IndexSet) {
        for idx in offsets.sorted(by: >) {
            exercises.remove(at: idx)
            viewModel.deleteExercise(exercises[idx])
        }
    }
}

#Preview {
    @Previewable @Environment(\.modelContext) var context
    ExerciseLibraryView().environmentObject(
        AppViewModel(context: context)
    )
}
