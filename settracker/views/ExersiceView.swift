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
                        let exercises = viewModel.exercises.filter { $0.category == category }

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
                ExerciseSheet(
                    category: category,
                    exercises: $viewModel.exercises,
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
    var category: Category
    @Binding var exercises: [Exercise]  // full exercise list
    var onClose: () -> Void

    @State private var newExerciseName: String = ""

    /// Indices of all exercises that belong to `category`
    private var categoryExerciseIndices: [Int] {
        exercises.enumerated()
            .compactMap { index, ex in ex.category == category && !ex.isDefault ? index : nil }
    }

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
            let defaultExercise = exercises.filter {$0.isDefault && $0.category == category}
            List {
                ForEach(defaultExercise, id: \.self){ ex in
                    HStack {
                        Text(ex.name.capitalized)
                            .textFieldStyle(.plain)
                        Spacer()
                    }
                }
                ForEach(categoryExerciseIndices, id: \.self) { idx in
                    HStack {
                        TextField("exerciseName", text: bindingForExercise(at: idx))
                            .textFieldStyle(.plain)
                        Spacer()
                        Button(role: .destructive) {
                            deleteExercise(at: idx)
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
                            .foregroundColor(newExerciseName.isEmpty ? .gray : .blue)
                    }
                    .disabled(newExerciseName.isEmpty)
                }
            }
            .listStyle(.insetGrouped)
        }
        .presentationDetents([.medium, .large]) // nice sheet sizes
    }

    // MARK: - Helpers

    private func bindingForExercise(at idx: Int) -> Binding<String> {
        Binding<String>(
            get: { exercises[idx].name },
            set: { newValue in
                var ex = exercises[idx]
                ex.name = newValue
                exercises[idx] = ex
            }
        )
    }

    private func addExercise() {
        let newExercise = Exercise(
            name: newExerciseName,
            category: category
        )
        exercises.append(newExercise)
        newExerciseName = ""
    }

    private func deleteExercise(at idx: Int) {
        exercises.remove(at: idx)
    }

    private func deleteExerciseAtOffsets(_ offsets: IndexSet) {
        let idsToDelete = offsets.map { categoryExerciseIndices[$0] }
        for idx in idsToDelete.sorted(by: >) {
            exercises.remove(at: idx)
        }
    }
}

#Preview {
    ExerciseLibraryView().environmentObject(AppViewModel())
}
