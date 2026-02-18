//
//  PanGestureView.swift
//  UIKitGesturesForSwiftUIPlayground
//
//  Created by Jacob Van Order on 2/17/26.
//

import SwiftUI
import UIKitGesturesForSwiftUI

/// A playground view that demonstrates the `MultiFingerPanGesture` from UIKitGesturesForSwiftUI.
///
/// The view is divided into three vertical sections:
/// 1. **Configuration** — steppers to adjust the minimum and maximum number of touches
///    required for the pan gesture to be recognized.
/// 2. **Gesture Playground** — a colored rectangle that can be dragged around with a pan gesture.
///    The rectangle changes color to reflect the current gesture state:
///    yellow for began, green for changed, red for ended, and blue when idle.
///    On gesture end, the rectangle animates back to its starting position.
/// 3. **Info Panel** — a read-only display of the current gesture state, touch location,
///    and active finger count.
struct PanGestureView: View {

    /// Represents the phase of a pan gesture lifecycle.
    ///
    /// Each case maps to a `UIGestureRecognizer.State` value reported by the underlying
    /// `UIPanGestureRecognizer`, plus an `idle` state for when no gesture is active.
    /// - `idle`: No gesture is in progress (rectangle shows default blue).
    /// - `began`: The user started panning with the required number of fingers.
    /// - `changed`: The user is actively moving their finger(s).
    /// - `ended`: The user lifted all fingers, completing the gesture.
    enum PanGestureState: Equatable {
        case idle
        case began
        case changed
        case ended

        /// A localized, human-readable description of this gesture state.
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

        /// The color used to tint the rectangle for this state.
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

    /// The view model that owns all mutable state for `PanGestureView`.
    ///
    /// Configuration properties (`minimumNumberOfTouches`, `maximumNumberOfTouches`) drive
    /// the gesture recognizer setup. Changing either value resets the rectangle position
    /// to the center via `didSet`. Gesture callback state (`rectangleOffset`, `dragStartOffset`,
    /// `gestureState`, `gestureLocation`, `numberOfTouches`) is updated in real time during
    /// pan interactions.
    @Observable
    class ViewModel {
        /// The minimum number of fingers required to recognize the pan gesture.
        /// Changing this value resets the rectangle to the center.
        var minimumNumberOfTouches: Int = 1 {
            didSet { rectangleOffset = .zero }
        }
        /// The maximum number of fingers allowed for the pan gesture.
        /// Changing this value resets the rectangle to the center.
        var maximumNumberOfTouches: Int = 2 {
            didSet { rectangleOffset = .zero }
        }
        /// The current position offset of the rectangle from center.
        var rectangleOffset: CGSize = .zero
        /// The rectangle's offset at the moment the gesture began, used as a baseline
        /// for computing the new position during the gesture.
        var dragStartOffset: CGSize = .zero
        /// The current phase of the pan gesture.
        var gestureState: PanGestureState = .idle
        /// The centroid of all touches in screen coordinates (`recognizer.location(in: nil)`).
        var gestureLocation: CGPoint = .zero
        /// The number of fingers currently on screen during the gesture.
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

    // MARK: - Configuration Section

    /// Displays steppers for adjusting the pan gesture's touch count configuration.
    ///
    /// - **Min Touches**: 1 up to the current max touches value.
    /// - **Max Touches**: current min touches value up to 5.
    ///
    /// The stepper ranges are interdependent — min cannot exceed max and vice versa.
    /// Changing either value resets the rectangle to center (handled by the view model's `didSet`).
    private struct ConfigurationSection: View {

        @Bindable var viewModel: ViewModel

        var body: some View {
            Form {
                Section {
                    Stepper("Min Touches: \(viewModel.minimumNumberOfTouches)",
                            value: $viewModel.minimumNumberOfTouches,
                            in: 1...viewModel.maximumNumberOfTouches)
                    .accessibilityValue("\(viewModel.minimumNumberOfTouches)")
                    .accessibilityHint(String(localized: "Adjusts the minimum number of fingers required to recognize the pan gesture."))

                    Stepper("Max Touches: \(viewModel.maximumNumberOfTouches)",
                            value: $viewModel.maximumNumberOfTouches,
                            in: viewModel.minimumNumberOfTouches...5)
                    .accessibilityValue("\(viewModel.maximumNumberOfTouches)")
                    .accessibilityHint(String(localized: "Adjusts the maximum number of fingers allowed for the pan gesture."))
                }
            }
            .formStyle(.grouped)
            .frame(height: 160)
        }
    }

    // MARK: - Gesture Playground

    /// The interactive area where the user performs pan gestures.
    ///
    /// A 150×150 rounded rectangle is centered in the available space and can be dragged
    /// using a `MultiFingerPanGesture`. Its fill color reflects the current ``PanGestureState``.
    ///
    /// Gesture callbacks:
    /// - **onBegan**: Saves the current offset as the drag baseline, updates state to `.began`.
    /// - **onChanged**: Adds the gesture's translation to the saved baseline to move the rectangle.
    /// - **onEnded**: Animates the rectangle back to its pre-drag position, then resets to `.idle`.
    private struct GesturePlayground: View {

        @Bindable var viewModel: ViewModel

        /// A human-readable summary of the current gesture configuration for VoiceOver.
        private var configurationSummary: String {
            String(localized: "Pan target. Requires \(viewModel.minimumNumberOfTouches) to \(viewModel.maximumNumberOfTouches) finger(s).")
        }

        var body: some View {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(viewModel.gestureState.rectangleColor)
                        .frame(width: 150, height: 150)
                        .offset(viewModel.rectangleOffset)
                        .accessibilityLabel(String(localized: "Pan target"))
                        .accessibilityValue(viewModel.gestureState.localizedState)
                        .accessibilityHint(configurationSummary)
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

    // MARK: - Info Panel

    /// A read-only display of the current gesture state, touch location, and finger count.
    ///
    /// Shows three `LabeledContent` rows:
    /// - **State**: The localized gesture phase name (Idle, Began, Changed, or Ended).
    /// - **Location**: The centroid of touches formatted as `(x, y)`.
    /// - **Touches**: The number of active fingers.
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
            .accessibilityElement(children: .contain)
            .accessibilityLabel(String(localized: "Gesture info"))
        }
    }
}

#Preview {
    NavigationStack {
        PanGestureView()
    }
}
