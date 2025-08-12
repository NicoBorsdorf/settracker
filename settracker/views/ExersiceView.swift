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

    var body: some View {
        NavigationStack {
            List {
                ForEach(Category.allCases, id: \.self) { category in
                    Section {
                        Text(category.rawValue).bold()
                        ForEach(viewModel.exercises.filter { $0.category.rawValue == category.rawValue }) { exercise in
                            VStack(alignment: .leading) {
                                Text(exercise.id).bold()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Exercise Library")
        }
    }
}

#Preview {
    ExerciseLibraryView(viewModel: AppViewModel())
}
