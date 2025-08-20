//
//  ExersiceView.swift
//  settracker
//
//  Created by Nico Borsdorf on 28.07.25.
//

import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var showExerciseSheet = false
    @State private var editingExercise: Exercise? = nil

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 20) {
                    ForEach(Category.allCases, id: \.self) { category in
                        let exercises = viewModel.exercises.filter { $0.category == category }
                        if !exercises.isEmpty {
                            SectionCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(category.rawValue.uppercased())
                                            .font(.headline)
                                        Spacer()
                                    }

                                    ForEach(exercises) { exercise in
                                        ExerciseRow(
                                            exercise: exercise,
                                            onEdit: { ex in
                                                editingExercise = ex
                                                showExerciseSheet = true
                                            },
                                            onDelete: {
                                                viewModel.exercises.removeAll { $0.id == exercise.id }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .sheet(isPresented: $showExerciseSheet) {
            ExerciseSheet(
                exercise: editingExercise,
                onCancel: {
                    editingExercise = nil
                    showExerciseSheet = false
                },
                onSave: { ex in
                    if let idx = viewModel.exercises.firstIndex(where: { $0.id == ex.id }) {
                        // update existing
                        viewModel.exercises[idx] = ex
                    } else {
                        // add new
                        viewModel.exercises.append(ex)
                    }
                    editingExercise = nil
                    showExerciseSheet = false
                }
            )
        }
    }

    // MARK: Header
    private var header: some View {
        HStack {
            Text("exerciseLibrary")
                .font(.headline)

            Spacer()

            Button {
                editingExercise = nil
                showExerciseSheet = true
            } label: {
                Label("add", systemImage: "plus")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground).shadow(radius: 0.5))
    }
}

// MARK: - Exercise Row
private struct ExerciseRow: View {
    var exercise: Exercise
    var onEdit: (Exercise) -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(exercise.name)
                    .font(.subheadline)
            }
            Spacer()
            Button {
                onEdit(exercise)
            } label: {
                Image(systemName: "pencil")
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Add/Edit Exercise Sheet
struct ExerciseSheet: View {
    var exercise: Exercise?
    var onCancel: () -> Void
    var onSave: (Exercise) -> Void

    @State private var name: String = ""
    @State private var category: Category = .push

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("exerciseName", text: $name)
                    Picker("category", selection: $category) {
                        ForEach(Category.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                }
            }
            .navigationTitle(exercise == nil ? "newExercise" : "editExercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("save") {
                        let newExercise = Exercise(
                            name: name,
                            category: category
                        )
                        onSave(newExercise)
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let ex = exercise {
                    name = ex.name
                    category = ex.category
                }
            }
        }
    }
}

//#Preview{
//ExerciseLibraryView(viewModel: AppViewModel())
//}
