//
//  _shared.swift
//  settracker
//
//  Created by Nico Borsdorf on 24.08.25.
//

import SwiftUI

struct SectionCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack { content }
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        .frame(maxWidth: .infinity)
    }
}
