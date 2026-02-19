//
//  PinchGestureView.swift
//  UIKitGesturesForSwiftUIPlayground
//
//  Created by Jacob Van Order on 2/18/26.
//

import Foundation
import SwiftUI
import UIKitGesturesForSwiftUI

/// A playground view that demonstrates the `MultiFingerPinchGesture` from UIKitGesturesForSwiftUI.
///
/// The view is divided into three vertical sections:
/// 1. **Configuration** — an informational section noting that the pinch gesture always
///    requires exactly two fingers. There are no configurable properties for this gesture.
/// 2. **Gesture Playground** — a colored rectangle that scales in response to pinch gestures.
///    The rectangle changes color to reflect the current gesture state:
///    yellow for began, green for changed, red for ended, and blue when idle.
///    On gesture end, the rectangle animates back to its original scale.
/// 3. **Info Panel** — a read-only display of the current gesture state, scale factor,
///    and velocity, updated in real time during the gesture.
struct PinchGestureView: View {

    /// Represents the phase of a pinch gesture lifecycle.
    ///
    /// Each case maps to a `UIGestureRecognizer.State` value reported by the underlying
    /// `UIPinchGestureRecognizer`:
    /// - `began`: The user placed two fingers and started pinching.
    /// - `changed`: The user is actively pinching (scale is updating).
    /// - `ended`: The user lifted their fingers, completing the gesture.
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

    /// The view model that owns all mutable state for `PinchGestureView`.
    ///
    /// The `MultiFingerPinchGesture` has no configurable properties — it always requires
    /// exactly two fingers. The view model tracks the current gesture state, the rectangle's
    /// scale, and the real-time scale and velocity values for the info panel.
    @Observable
    class ViewModel {
        /// The most recent gesture state, used to color the rectangle.
        /// `nil` means the gesture is idle (rectangle shows its default blue color).
        var currentState: GestureState?
        /// The current scale factor applied to the rectangle during a pinch gesture.
        var currentScale: CGFloat = 1.0
        /// The scale factor at the moment the gesture began, used as a baseline
        /// for computing the cumulative scale during the gesture.
        var gestureStartScale: CGFloat = 1.0
        /// The recognizer's scale factor relative to the start of the current gesture (1.0 = no change).
        var scale: CGFloat = 1.0
        /// The rate of scale change per second, updated in real time during the gesture.
        var velocity: CGFloat = 0.0
    }

    @State private var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ConfigurationSection()
            GesturePlayground(viewModel: viewModel)
            InfoPanel(viewModel: viewModel)
        }
        .navigationTitle(String(localized: "Pinch Gesture"))
    }

    // MARK: - Configuration Section

    /// An informational section explaining that the pinch gesture has no configurable properties.
    ///
    /// Unlike other gesture views, the `UIPinchGestureRecognizer` always requires exactly
    /// two fingers and has no adjustable parameters. This section communicates that to the user.
    private struct ConfigurationSection: View {
        var body: some View {
            Form {
                Section {
                    Label {
                        Text(String(localized: "Pinch always requires two fingers."))
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "hand.pinch")
                    }
                }
            }
            .formStyle(.grouped)
            .frame(height: 110)
        }
    }

    // MARK: - Gesture Playground

    /// The interactive area where the user performs pinch gestures.
    ///
    /// A 150×150 rounded rectangle is centered in the available space and scales in response
    /// to pinch gestures. Its fill color reflects the current ``GestureState``: yellow when
    /// the pinch begins, green while the fingers move, red when lifted, and blue when idle.
    ///
    /// A `MultiFingerPinchGesture` is attached to the entire area. Its three callbacks
    /// (`onBegan`, `onChanged`, `onEnded`) each update the view model's state and scale.
    /// On gesture end, the scale animates back to 1.0.
    private struct GesturePlayground: View {

        var viewModel: ViewModel

        var body: some View {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(viewModel.currentState?.color ?? .blue)
                        .frame(width: 150, height: 150)
                        .scaleEffect(viewModel.currentScale)
                        .accessibilityLabel(String(localized: "Pinch target"))
                        .accessibilityValue(viewModel.currentState?.localizedString ?? String(localized: "Idle"))
                        .accessibilityHint(String(localized: "Pinch with two fingers to scale the rectangle."))
                }
                .contentShape(Rectangle())
                .gesture(
                    MultiFingerPinchGesture()
                        .onBegan { recognizer in
                            viewModel.gestureStartScale = viewModel.currentScale
                            viewModel.currentState = .began
                            viewModel.scale = recognizer.scale
                            viewModel.velocity = recognizer.velocity
                        }
                        .onChanged { recognizer in
                            viewModel.currentScale = viewModel.gestureStartScale * recognizer.scale
                            viewModel.currentState = .changed
                            viewModel.scale = recognizer.scale
                            viewModel.velocity = recognizer.velocity
                        }
                        .onEnded { recognizer in
                            viewModel.currentState = .ended
                            viewModel.scale = recognizer.scale
                            viewModel.velocity = recognizer.velocity
                            withAnimation(.easeOut) {
                                viewModel.currentScale = 1.0
                            } completion: {
                                viewModel.currentState = nil
                            }
                        }
                )
        }
    }

    // MARK: - Info Panel

    /// A read-only display of the current gesture state, scale factor, and velocity.
    ///
    /// Shows three `LabeledContent` rows updated in real time during the pinch gesture:
    /// - **State**: The localized gesture phase name (Idle, Began, Changed, or Ended).
    /// - **Scale**: The recognizer's current scale factor relative to the gesture start.
    /// - **Velocity**: The rate of scale change per second.
    private struct InfoPanel: View {

        var viewModel: ViewModel

        var body: some View {
            Form {
                Section("Gesture Info") {
                    LabeledContent(String(localized: "State"),
                                   value: viewModel.currentState?.localizedString ?? String(localized: "Idle"))
                    LabeledContent(String(localized: "Scale"),
                                   value: Float(viewModel.scale).formatted(.number.precision(.fractionLength(2))))
                    LabeledContent(String(localized: "Velocity"),
                                   value: Float(viewModel.velocity).formatted(.number.precision(.fractionLength(2))))
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
        PinchGestureView()
    }
}
