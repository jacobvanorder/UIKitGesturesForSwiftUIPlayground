//
//  ContentView.swift
//  UIKitGesturesForSwiftUIPlayground
//
//  Created by Jacob Van Order on 2/17/26.
//

import SwiftUI

enum Route: Hashable, CaseIterable {
    case panGesture
    case tapGesture
}

extension Route {
    var title: String {
        switch self {
        case .panGesture:
            return String(localized: "Pan Gesture")
        case .tapGesture:
            return String(localized: "Tap Gesture")
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List(Route.allCases, id: \.self) { route in
                NavigationLink(value: route) {
                    Text(route.title)
                }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .panGesture:
                    PanGestureView()
                case .tapGesture:
                    TapGestureView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
