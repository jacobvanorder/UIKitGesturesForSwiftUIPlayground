//
//  CustomTransformGestureView.swift
//  UIKitGesturesForSwiftUIPlayground
//
//  Created by Jacob Van Order on 2/19/26.
//

import SwiftUI
import UIKitGesturesForSwiftUI

/// A playground view that demonstrates the `MultiFingerTransformGesture` from UIKitGesturesForSwiftUI.
///
/// This gesture combines pan, pinch, and rotation into a single two-finger gesture using a custom
/// `TransformGestureRecognizer`. The view is divided into three vertical sections:
/// 1. **Configuration** — an informational section noting that the transform gesture always
///    requires exactly two fingers. There are no configurable properties for this gesture.
/// 2. **Gesture Playground** — a colored rectangle that simultaneously translates, scales,
///    and rotates in response to two-finger gestures. The rectangle changes color to reflect
///    the current gesture state: yellow for began, green for changed, red for ended, and blue
///    when idle. On gesture end, the rectangle animates back to its original transform.
/// 3. **Info Panel** — a read-only display of the current gesture state, translation offset,
///    scale factor, and rotation angle, updated in real time during the gesture.
struct CustomTransformGestureView: View {

    /// Represents the phase of a transform gesture lifecycle.
    ///
    /// Each case maps to a `UIGestureRecognizer.State` value reported by the underlying
    /// `TransformGestureRecognizer`:
    /// - `began`: The user placed two fingers and started transforming.
    /// - `changed`: The user is actively moving, pinching, or rotating (values are updating).
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

    /// The view model that owns all mutable state for `CustomTransformGestureView`.
    ///
    /// The `MultiFingerTransformGesture` has no configurable properties — it always requires
    /// exactly two fingers. The view model tracks the current gesture state, the rectangle's
    /// combined transform (translation, scale, rotation), and the real-time values for the
    /// info panel.
    @Observable
    @MainActor
    class ViewModel {
        /// The most recent gesture state, used to color the rectangle.
        /// `nil` means the gesture is idle (rectangle shows its default blue color).
        var currentState: GestureState?

        // MARK: Applied transform values

        /// The current translation offset applied to the rectangle.
        var currentTranslation: CGSize = .zero
        /// The current scale factor applied to the rectangle.
        var currentScale: CGFloat = 1.0
        /// The current rotation angle applied to the rectangle (in radians).
        var currentRotation: CGFloat = 0.0

        // MARK: Gesture start baselines

        /// The translation at the moment the gesture began.
        var gestureStartTranslation: CGSize = .zero
        /// The scale factor at the moment the gesture began.
        var gestureStartScale: CGFloat = 1.0
        /// The rotation angle at the moment the gesture began (in radians).
        var gestureStartRotation: CGFloat = 0.0

        // MARK: Real-time recognizer values for InfoPanel

        /// The recognizer's translation since the gesture started.
        var translation: CGPoint = .zero
        /// The recognizer's scale factor relative to the initial finger distance (1.0 = no change).
        var scale: CGFloat = 1.0
        /// The recognizer's rotation in radians since the gesture started.
        var rotation: CGFloat = 0.0
    }

    @State private var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ConfigurationSection()
            GesturePlayground(viewModel: viewModel)
            InfoPanel(viewModel: viewModel)
        }
        .navigationTitle(String(localized: "Transform Gesture"))
    }

    // MARK: - Configuration Section

    /// An informational section explaining that the transform gesture has no configurable properties.
    ///
    /// The custom `TransformGestureRecognizer` always requires exactly two fingers and combines
    /// pan, pinch, and rotation into a single gesture. This section communicates that to the user.
    private struct ConfigurationSection: View {
        var body: some View {
            Form {
                Section {
                    Label {
                        Text(String(localized: "Transform combines pan, pinch, and rotation. Requires two fingers."))
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "hand.draw")
                    }
                }
            }
            .formStyle(.grouped)
            .frame(height: 110)
        }
    }

    // MARK: - Gesture Playground

    /// The interactive area where the user performs transform gestures.
    ///
    /// A 150×150 rounded rectangle is centered in the available space and simultaneously
    /// translates, scales, and rotates in response to two-finger gestures. Its fill color
    /// reflects the current ``GestureState``: yellow when the gesture begins, green while
    /// the fingers move, red when lifted, and blue when idle.
    ///
    /// A `MultiFingerTransformGesture` is attached to the entire area. Its three callbacks
    /// (`onBegan`, `onChanged`, `onEnded`) each update the view model's state and transform.
    /// On gesture end, all transforms animate back to identity (centered, no scale, no rotation).
    private struct GesturePlayground: View {

        var viewModel: ViewModel

        var body: some View {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(viewModel.currentState?.color ?? .blue)
                        .frame(width: 150, height: 150)
                        .offset(viewModel.currentTranslation)
                        .scaleEffect(viewModel.currentScale)
                        .rotationEffect(.radians(viewModel.currentRotation))
                        .accessibilityLabel(String(localized: "Transform target"))
                        .accessibilityValue(viewModel.currentState?.localizedString ?? String(localized: "Idle"))
                        .accessibilityHint(String(localized: "Use two fingers to pan, pinch, and rotate the rectangle simultaneously."))
                }
                .contentShape(Rectangle())
                .gesture(
                    MultiFingerTransformGesture()
                        .onBegan { recognizer in
                            viewModel.gestureStartTranslation = viewModel.currentTranslation
                            viewModel.gestureStartScale = viewModel.currentScale
                            viewModel.gestureStartRotation = viewModel.currentRotation
                            viewModel.currentState = .began
                            viewModel.translation = recognizer.translation
                            viewModel.scale = recognizer.scale
                            viewModel.rotation = recognizer.rotation
                            withAnimation(.easeOut) {
                                viewModel.currentTranslation = .zero
                                viewModel.currentScale = 1.0
                                viewModel.currentRotation = 0.0
                            } completion: {
                                viewModel.currentState = nil
                            }
                        }
                )
        }
    }

    // MARK: - Info Panel

    /// A read-only display of the current gesture state, translation, scale, and rotation.
    ///
    /// Shows four `LabeledContent` rows updated in real time during the transform gesture:
    /// - **State**: The localized gesture phase name (Idle, Began, Changed, or Ended).
    /// - **Translation**: The recognizer's translation as an (x, y) offset in points.
    /// - **Scale**: The recognizer's scale factor relative to the initial finger distance.
    /// - **Rotation**: The recognizer's rotation converted from radians to degrees.
    private struct InfoPanel: View {

        var viewModel: ViewModel

        /// The current rotation converted from radians to degrees.
        private var rotationDegrees: CGFloat {
            viewModel.rotation * 180 / .pi
        }

        var body: some View {
            Form {
                Section(String(localized: "Gesture Info")) {
                    LabeledContent(String(localized: "State"),
                                   value: viewModel.currentState?.localizedString ?? String(localized: "Idle"))
                    LabeledContent(String(localized: "Translation"),
                                   value: String(format: "(%.1f, %.1f)",
                                                 viewModel.translation.x,
                                                 viewModel.translation.y))
                    LabeledContent(String(localized: "Scale"),
                                   value: String(format: "%.2f", viewModel.scale))
                    LabeledContent(String(localized: "Rotation"),
                                   value: String(format: "%.1f\u{00B0}", rotationDegrees))
                }
            }
            .formStyle(.grouped)
            .frame(height: 240)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(String(localized: "Gesture info"))
        }
    }
}

#Preview {
    NavigationStack {
        CustomTransformGestureView()
    }
}
