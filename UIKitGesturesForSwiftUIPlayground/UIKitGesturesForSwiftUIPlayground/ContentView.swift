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
    case longPressGesture
    case swipeGesture
    case pinchGesture
    case rotationGesture
}

extension Route {
    var title: String {
        switch self {
        case .panGesture:
            return String(localized: "Pan Gesture")
        case .tapGesture:
            return String(localized: "Tap Gesture")
        case .longPressGesture:
            return String(localized: "Long Press Gesture")
        case .swipeGesture:
            return String(localized: "Swipe Gesture")
        case .pinchGesture:
            return String(localized: "Pinch Gesture")
        case .rotationGesture:
            return String(localized: "Rotation Gesture")
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
                case .longPressGesture:
                    LongPressGestureView()
                case .swipeGesture:
                    SwipeGestureView()
                case .pinchGesture:
                    PinchGestureView()
                case .rotationGesture:
                    RotationGestureView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
