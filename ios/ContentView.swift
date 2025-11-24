//
//  ContentView.swift
//  its-algebra
//
//  Main content view with split canvas layout
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        DrawingCanvasView()
            .ignoresSafeArea(.all)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

