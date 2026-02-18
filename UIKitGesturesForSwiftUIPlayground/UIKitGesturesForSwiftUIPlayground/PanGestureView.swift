//
//  PanGestureView.swift
//  UIKitGesturesForSwiftUIPlayground
//
//  Created by Jacob Van Order on 2/17/26.
//

import SwiftUI
import UIKitGesturesForSwiftUI

struct PanGestureView: View {

    enum PanGestureState: Equatable {
        case idle
        case began
        case changed
        case ended

        var localizedState: String {
            switch self {
            case .idle:
                String(localized: "Idle")
            case .began:
                String(localized: "Began")
            case .changed:
                String(localized: "Changed")
            case .ended:
                String(localized: "Ended")
            }
        }

        var rectangleColor: Color {
            switch self {
            case .idle:
                    .blue
            case .began:
                    .yellow
            case .changed:
                    .green
            case .ended:
                    .red
            }
        }
    }

    @Observable
    class ViewModel {
        var minimumNumberOfTouches: Int = 1 {
            didSet { rectangleOffset = .zero }
        }
        var maximumNumberOfTouches: Int = 2 {
            didSet { rectangleOffset = .zero }
        }
        var rectangleOffset: CGSize = .zero
        var dragStartOffset: CGSize = .zero
        var gestureState: PanGestureState = .idle
        var gestureLocation: CGPoint = .zero
        var numberOfTouches: Int = 0
    }

    @State private var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ConfigurationSection(viewModel: viewModel)
            GesturePlayground(viewModel: viewModel)
            InfoPanel(viewModel: viewModel)
        }
        .navigationTitle("Pan Gesture")
    }

    private struct ConfigurationSection: View {

        @Bindable var viewModel: ViewModel

        var body: some View {
            Form {
                Section {
                    Stepper("Min Touches: \(viewModel.minimumNumberOfTouches)",
                            value: $viewModel.minimumNumberOfTouches,
                            in: 1...viewModel.maximumNumberOfTouches)
                    Stepper("Max Touches: \(viewModel.maximumNumberOfTouches)",
                            value: $viewModel.maximumNumberOfTouches,
                            in: viewModel.minimumNumberOfTouches...5)
                }
            }
            .formStyle(.grouped)
            .frame(height: 160)
        }
    }

    private struct GesturePlayground: View {

        @Bindable var viewModel: ViewModel

        var body: some View {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(viewModel.gestureState.rectangleColor)
                        .frame(width: 150, height: 150)
                        .offset(viewModel.rectangleOffset)
                }
                .contentShape(Rectangle())
                .gesture(
                    MultiFingerPanGesture(
                        minimumNumberOfTouches: viewModel.minimumNumberOfTouches,
                        maximumNumberOfTouches: viewModel.maximumNumberOfTouches
                    )
                    .onBegan { recognizer in
                        viewModel.dragStartOffset = viewModel.rectangleOffset
                        viewModel.gestureState = .began
                        viewModel.gestureLocation = recognizer.location(in: nil)
                        viewModel.numberOfTouches = recognizer.numberOfTouches
                    }
                        .onChanged { recognizer in
                            let translation = recognizer.translation(in: nil)
                            viewModel.rectangleOffset = CGSize(
                                width: viewModel.dragStartOffset.width + translation.x,
                                height: viewModel.dragStartOffset.height + translation.y
                            )
                            viewModel.gestureState = .changed
                            viewModel.gestureLocation = recognizer.location(in: nil)
                            viewModel.numberOfTouches = recognizer.numberOfTouches
                        }
                        .onEnded { _ in
                            viewModel.gestureState = .ended
                            viewModel.numberOfTouches = 0
                            withAnimation {
                                viewModel.rectangleOffset = viewModel.dragStartOffset
                            } completion: {
                                viewModel.gestureState = .idle
                            }
                        }
                )
        }
    }

    private struct InfoPanel: View {

        var viewModel: ViewModel

        var body: some View {
            Form {
                Section("Gesture Info") {
                    LabeledContent("State", value: viewModel.gestureState.localizedState)
                    LabeledContent("Location",
                                   value: String(format: "(%.1f, %.1f)",
                                                 viewModel.gestureLocation.x,
                                                 viewModel.gestureLocation.y))
                    LabeledContent("Touches", value: "\(viewModel.numberOfTouches)")
                }
            }
            .formStyle(.grouped)
            .frame(height: 200)
        }
    }
}

#Preview {
    NavigationStack {
        PanGestureView()
    }
}
