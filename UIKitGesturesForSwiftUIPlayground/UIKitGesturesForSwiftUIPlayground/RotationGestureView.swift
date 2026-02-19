//
//  RotationGestureView.swift
//  UIKitGesturesForSwiftUIPlayground
//
//  Created by Jacob Van Order on 2/19/26.
//

import SwiftUI
import UIKitGesturesForSwiftUI

/// A playground view that demonstrates the `MultiFingerRotationGesture` from UIKitGesturesForSwiftUI.
///
/// The view is divided into three vertical sections:
/// 1. **Configuration** — an informational section noting that the rotation gesture always
///    requires exactly two fingers. There are no configurable properties for this gesture.
/// 2. **Gesture Playground** — a colored rectangle that rotates in response to two-finger
///    rotation gestures. The rectangle changes color to reflect the current gesture state:
///    yellow for began, green for changed, red for ended, and blue when idle.
///    On gesture end, the rectangle animates back to its original rotation.
/// 3. **Info Panel** — a read-only display of the current gesture state, rotation angle
///    (in degrees), and rotational velocity, updated in real time during the gesture.
struct RotationGestureView: View {

    /// Represents the phase of a rotation gesture lifecycle.
    ///
    /// Each case maps to a `UIGestureRecognizer.State` value reported by the underlying
    /// `UIRotationGestureRecognizer`:
    /// - `began`: The user placed two fingers and started rotating.
    /// - `changed`: The user is actively rotating (angle is updating).
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

    /// The view model that owns all mutable state for `RotationGestureView`.
    ///
    /// The `MultiFingerRotationGesture` has no configurable properties — it always requires
    /// exactly two fingers. The view model tracks the current gesture state, the rectangle's
    /// rotation angle, and the real-time rotation and velocity values for the info panel.
    @Observable
    class ViewModel {
        /// The most recent gesture state, used to color the rectangle.
        /// `nil` means the gesture is idle (rectangle shows its default blue color).
        var currentState: GestureState?
        /// The current rotation angle applied to the rectangle (in radians).
        var currentRotation: CGFloat = 0.0
        /// The rotation angle at the moment the gesture began, used as a baseline
        /// for computing the cumulative rotation during the gesture.
        var gestureStartRotation: CGFloat = 0.0
        /// The recognizer's rotation value in radians relative to the start of the current gesture.
        var rotation: CGFloat = 0.0
        /// The rate of rotation change in radians per second, updated in real time during the gesture.
        var velocity: CGFloat = 0.0
    }

    @State private var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ConfigurationSection()
            GesturePlayground(viewModel: viewModel)
            InfoPanel(viewModel: viewModel)
        }
        .navigationTitle(String(localized: "Rotation Gesture"))
    }

    // MARK: - Configuration Section

    /// An informational section explaining that the rotation gesture has no configurable properties.
    ///
    /// Unlike other gesture views, the `UIRotationGestureRecognizer` always requires exactly
    /// two fingers and has no adjustable parameters. This section communicates that to the user.
    private struct ConfigurationSection: View {
        var body: some View {
            Form {
                Section {
                    Label {
                        Text(String(localized: "Rotation always requires two fingers."))
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "rotate.right")
                    }
                }
            }
            .formStyle(.grouped)
            .frame(height: 110)
        }
    }

    // MARK: - Gesture Playground

    /// The interactive area where the user performs rotation gestures.
    ///
    /// A 150×150 rounded rectangle is centered in the available space and rotates in response
    /// to two-finger rotation gestures. Its fill color reflects the current ``GestureState``:
    /// yellow when the rotation begins, green while the fingers move, red when lifted, and
    /// blue when idle.
    ///
    /// A `MultiFingerRotationGesture` is attached to the entire area. Its three callbacks
    /// (`onBegan`, `onChanged`, `onEnded`) each update the view model's state and rotation.
    /// On gesture end, the rotation animates back to 0.
    private struct GesturePlayground: View {

        var viewModel: ViewModel

        var body: some View {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(viewModel.currentState?.color ?? .blue)
                        .frame(width: 150, height: 150)
                        .rotationEffect(.radians(viewModel.currentRotation))
                        .accessibilityLabel(String(localized: "Rotation target"))
                        .accessibilityValue(viewModel.currentState?.localizedString ?? String(localized: "Idle"))
                        .accessibilityHint(String(localized: "Rotate with two fingers to turn the rectangle."))
                }
                .contentShape(Rectangle())
                .gesture(
                    MultiFingerRotationGesture()
                        .onBegan { recognizer in
                            viewModel.gestureStartRotation = viewModel.currentRotation
                            viewModel.currentState = .began
                            viewModel.rotation = recognizer.rotation
                            viewModel.velocity = recognizer.velocity
                        }
                        .onChanged { recognizer in
                            viewModel.currentRotation = viewModel.gestureStartRotation + recognizer.rotation
                            viewModel.currentState = .changed
                            viewModel.rotation = recognizer.rotation
                            viewModel.velocity = recognizer.velocity
                        }
                        .onEnded { recognizer in
                            viewModel.currentState = .ended
                            viewModel.rotation = recognizer.rotation
                            viewModel.velocity = recognizer.velocity
                            withAnimation(.easeOut) {
                                viewModel.currentRotation = 0.0
                            } completion: {
                                viewModel.currentState = nil
                            }
                        }
                )
        }
    }

    // MARK: - Info Panel

    /// A read-only display of the current gesture state, rotation angle, and rotational velocity.
    ///
    /// Shows three `LabeledContent` rows updated in real time during the rotation gesture:
    /// - **State**: The localized gesture phase name (Idle, Began, Changed, or Ended).
    /// - **Rotation**: The recognizer's current rotation converted from radians to degrees.
    /// - **Velocity**: The rate of rotation change in degrees per second.
    private struct InfoPanel: View {

        var viewModel: ViewModel

        /// The current rotation converted from radians to degrees.
        private var rotationDegrees: CGFloat {
            viewModel.rotation * 180 / .pi
        }

        /// The current velocity converted from radians/sec to degrees/sec.
        private var velocityDegrees: CGFloat {
            viewModel.velocity * 180 / .pi
        }

        var body: some View {
            Form {
                Section(String(localized: "Gesture Info")) {
                    LabeledContent(String(localized: "State"),
                                   value: viewModel.currentState?.localizedString ?? String(localized: "Idle"))
                    LabeledContent(String(localized: "Rotation"),
                                   value: String(format: "%.1f\u{00B0}", rotationDegrees))
                    LabeledContent(String(localized: "Velocity"),
                                   value: String(format: "%.1f\u{00B0}/s", velocityDegrees))
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
        RotationGestureView()
    }
}
