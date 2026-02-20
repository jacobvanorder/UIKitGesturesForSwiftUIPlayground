//
//  LongPressGestureView.swift
//  UIKitGesturesForSwiftUIPlayground
//
//  Created by Jacob Van Order on 2/18/26.
//

import SwiftUI
import UIKitGesturesForSwiftUI

/// A playground view that demonstrates the `MultiFingerLongPressGesture` from UIKitGesturesForSwiftUI.
///
/// The view is divided into three vertical sections:
/// 1. **Configuration** — steppers to adjust minimum press duration, number of touches required,
///    and number of taps required before the long press begins.
/// 2. **Gesture Playground** — a colored rectangle that responds to long press gestures.
///    The rectangle changes color to reflect the current gesture state:
///    yellow for began, green for changed, red for ended, and blue when idle.
/// 3. **Info Panel** — a read-only display of the current gesture state, touch location,
///    and finger count, updated in real time during the gesture.
struct LongPressGestureView: View {

    /// Represents the phase of a long press gesture lifecycle.
    ///
    /// Each case maps to a `UIGestureRecognizer.State` value reported by the underlying
    /// `UILongPressGestureRecognizer`:
    /// - `began`: The user held their finger(s) for at least `minimumPressDuration`.
    /// - `changed`: The user moved their finger(s) while still pressing.
    /// - `ended`: The user lifted all fingers, completing the gesture.
    enum GestureState: Equatable {
        case began
        case changed
        case ended

        /// The color used to tint the rectangle for this state.
        var color: Color {
            switch self {
            case .began: .yellow
            case .changed: .green
            case .ended: .red
            }
        }

        /// A localized, human-readable description of this gesture state.
        var localizedString: String {
            switch self {
            case .began:
                String(localized: "Began")
            case .changed:
                String(localized: "Changed")
            case .ended:
                String(localized: "Ended")
            }
        }
    }

    /// The view model that owns all mutable state for `LongPressGestureView`.
    ///
    /// Configuration properties (`minimumPressDuration`, `numberOfTouchesRequired`,
    /// `numberOfTapsRequired`) drive the gesture recognizer setup. The remaining properties
    /// track the current gesture state, touch location, and finger count for the info panel.
    @Observable
    class ViewModel {
        /// The minimum duration (in seconds) the user must press before the gesture is recognized.
        /// Adjustable from 0.25 to 3.0 seconds in 0.25-second increments.
        var minimumPressDuration: TimeInterval = 0.5
        /// The number of fingers that must be on screen for the gesture to be recognized (1–5).
        var numberOfTouchesRequired: Int = 1
        /// The number of taps required before the long press phase begins (0–5).
        /// A value of 0 means no preliminary taps are needed.
        var numberOfTapsRequired: Int = 0
        /// The most recent gesture state, used to color the rectangle.
        /// `nil` means the gesture is idle (rectangle shows its default blue color).
        var currentState: GestureState?
        /// The centroid of all touches in screen coordinates (`recognizer.location(in: nil)`).
        var gestureLocation: CGPoint = .zero
        /// The number of fingers on screen during the gesture.
        var numberOfTouches: Int = 0
    }

    @State private var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ConfigurationSection(viewModel: viewModel)
            GesturePlayground(viewModel: viewModel)
            InfoPanel(viewModel: viewModel)
        }
        .navigationTitle(String(localized: "Long Press Gesture"))
    }

    // MARK: - Configuration Section

    /// Displays steppers for adjusting the long press gesture's configuration.
    ///
    /// - **Min Duration**: 0.25–3.0 seconds in 0.25s increments.
    /// - **Touches Required**: 1–5 simultaneous fingers.
    /// - **Taps Required**: 0–5 taps before the long press begins.
    private struct ConfigurationSection: View {

        @Bindable var viewModel: ViewModel

        var body: some View {
            Form {
                Section {
                    Stepper("Min Duration: \(viewModel.minimumPressDuration, format: .number.precision(.fractionLength(2)))s",
                            value: $viewModel.minimumPressDuration,
                            in: 0.25...3.0,
                            step: 0.25)
                    .accessibilityValue("\(viewModel.minimumPressDuration, format: .number.precision(.fractionLength(2))) seconds")
                    .accessibilityHint(String(localized: "Adjusts the minimum duration required to recognize the long press."))

                    Stepper("Touches Required: \(viewModel.numberOfTouchesRequired)",
                            value: $viewModel.numberOfTouchesRequired,
                            in: 1...5)
                    .accessibilityValue("\(viewModel.numberOfTouchesRequired)")
                    .accessibilityHint(String(localized: "Adjusts the number of fingers required to recognize the long press."))

                    Stepper("Taps Required: \(viewModel.numberOfTapsRequired)",
                            value: $viewModel.numberOfTapsRequired,
                            in: 0...5)
                    .accessibilityValue("\(viewModel.numberOfTapsRequired)")
                    .accessibilityHint(String(localized: "Adjusts the number of taps required before the long press begins."))
                }
            }
            .formStyle(.grouped)
            .frame(height: 210)
        }
    }

    // MARK: - Gesture Playground

    /// The interactive area where the user performs long press gestures.
    ///
    /// A 150×150 rounded rectangle is centered in the available space. Its fill color
    /// reflects the current ``GestureState``: yellow when the press begins, green while
    /// the finger moves, red when lifted, and blue when idle.
    ///
    /// A `MultiFingerLongPressGesture` is attached to the entire area. Its three callbacks
    /// (`onBegan`, `onChanged`, `onEnded`) each update the view model's state and location.
    private struct GesturePlayground: View {

        var viewModel: ViewModel

        /// A human-readable summary of the current gesture configuration for VoiceOver.
        private var configurationSummary: String {
            String(localized: "Long press target. Requires \(viewModel.numberOfTouchesRequired) finger(s) held for \(viewModel.minimumPressDuration, format: .number.precision(.fractionLength(2))) seconds.")
        }

        var body: some View {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(viewModel.currentState?.color ?? .blue)
                        .frame(width: 150, height: 150)
                        .accessibilityLabel(String(localized: "Long press target"))
                        .accessibilityValue(viewModel.currentState?.localizedString ?? String(localized: "Idle"))
                        .accessibilityHint(configurationSummary)
                }
                .contentShape(Rectangle())
                .gesture(
                    MultiFingerLongPressGesture(
                        minimumPressDuration: viewModel.minimumPressDuration,
                        numberOfTouchesRequired: viewModel.numberOfTouchesRequired,
                        numberOfTapsRequired: viewModel.numberOfTapsRequired
                    )
                    .onBegan { recognizer in
                        viewModel.currentState = .began
                        viewModel.gestureLocation = recognizer.location(in: nil)
                        viewModel.numberOfTouches = recognizer.numberOfTouches
                    }
                    .onChanged { recognizer in
                        viewModel.currentState = .changed
                        viewModel.gestureLocation = recognizer.location(in: nil)
                        viewModel.numberOfTouches = recognizer.numberOfTouches
                    }
                    .onEnded { recognizer in
                        viewModel.currentState = .ended
                        viewModel.gestureLocation = recognizer.location(in: nil)
                        viewModel.numberOfTouches = recognizer.numberOfTouches
                    }
                )
        }
    }

    // MARK: - Info Panel

    /// A read-only display of the current gesture state, touch location, and finger count.
    ///
    /// Shows three `LabeledContent` rows updated in real time during the long press gesture:
    /// - **State**: The localized gesture phase name (Idle, Began, Changed, or Ended).
    /// - **Location**: The centroid of touches in screen coordinates as an (x, y) offset in points.
    /// - **Touches**: The number of fingers currently on screen.
    private struct InfoPanel: View {

        var viewModel: ViewModel

        var body: some View {
            Form {
                Section(String(localized: "Gesture Info")) {
                    LabeledContent(String(localized: "State"),
                                   value: viewModel.currentState?.localizedString ?? String(localized: "Idle"))
                    LabeledContent(String(localized: "Location"),
                                   value: String(format: "(%.1f, %.1f)",
                                                 viewModel.gestureLocation.x,
                                                 viewModel.gestureLocation.y))
                    LabeledContent(String(localized: "Touches"),
                                   value: "\(viewModel.numberOfTouches)")
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
        LongPressGestureView()
    }
}
