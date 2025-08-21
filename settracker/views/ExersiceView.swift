//
//  ExersiceView.swift
//  settracker
//
//  Created by Nico Borsdorf on 28.07.25.
//

import SwiftData
import SwiftUI

struct ExerciseLibraryView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var editingCategory: Category? = nil

    init(
        viewModel: AppViewModel,
    ) {
        self.viewModel = viewModel
    }

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
                                HStack {
                                    Text(category.rawValue.uppercased())
                                        .font(.headline)
                                    Spacer()
                                    if #available(iOS 26.0, *) {
                                        Button(
                                            "",
                                            systemImage: "pencil",
                                            role: .confirm
                                        ) {
                                            editingCategory = category
                                        }
                                    } else {
                                        Button("", systemImage: "plus") {
                                            editingCategory = category
                                        }.backgroundStyle(.blue)
                                    }
                                }

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
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("exerciseLibrary")
            .sheet(item: $editingCategory) { category in
                ExerciseSheet(
                    category: category,
                    exercises: $viewModel.exercises,
                    onCancel: {
                        editingCategory = nil
                    },
                    onSave: { ex in
                        if let idx = viewModel.exercises.firstIndex(where: {
                            $0.id == ex.id
                        }) {
                            // update existing
                            viewModel.exercises[idx] = ex
                        } else {
                            // add new
                            viewModel.exercises.append(ex)
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Exercise Row
private struct ExerciseRow: View {
    var exercise: Exercise

    var body: some View {
        HStack {
            Text(exercise.name)
                .font(.subheadline)
            Spacer()
            Label {
                Text("delete").padding(0)
            } icon: {
                Image(systemName: "arrow.left").padding(0)
            }.font(.caption2).foregroundStyle(Color.gray)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Category Exercise Sheet
struct ExerciseSheet: View {
    var category: Category
    @Binding var exercises: [Exercise]  // pass in the full exercise list
    var onCancel: () -> Void
    var onSave: (Exercise) -> Void  // called when a new exercise is added

    @State private var newExerciseName: String = ""

    // Filtered exercises for this category
    private var categoryExercises: [Exercise] {
        exercises.filter { $0.category == category }
    }

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(categoryExercises, id: \.self) { exercise in
                        ExerciseRow(exercise: exercise)
                    }
                    .onDelete(perform: deleteExercise)

                    // Add new exercise section
                    VStack {
                        TextField("exerciseName", text: $newExerciseName)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)

                        Button {
                            addExercise()
                        } label: {
                            Label("add", systemImage: "plus")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    newExerciseName.isEmpty
                                        ? Color.gray.opacity(0.3) : Color.blue
                                )
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(newExerciseName.isEmpty)
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                }

            }
            .navigationTitle(category.id.uppercased())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("close") { onCancel() }
                }
            }
        }
    }

    // MARK: - Actions
    private func addExercise() {
        let newExercise = Exercise(
            name: newExerciseName,
            category: category
        )
        exercises.append(newExercise)
        onSave(newExercise)
        newExerciseName = ""
    }

    private func deleteExercise(at offsets: IndexSet) {
        let idsToDelete = offsets.map { categoryExercises[$0].id }
        exercises.removeAll { idsToDelete.contains($0.id) }
    }
}

#Preview {
    ExerciseLibraryView(viewModel: AppViewModel())
}
