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
/// 3. **Event Log** — a scrolling list of gesture state transitions. Each entry shows a timestamp,
///    the gesture state, touch location, and finger count. Entries automatically fade out and
///    are removed after 3 seconds.
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

        /// The color used to tint the rectangle and the event log label for this state.
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

    /// A single recorded gesture state transition, displayed in the event log.
    ///
    /// Each event captures the state, the touch location in screen coordinates,
    /// the number of active touches, and the wall-clock time it occurred.
    /// The `isExpiring` flag drives a fade-out animation before the event is removed.
    struct GestureEvent: Identifiable {
        let id = UUID()
        /// The gesture phase at the time of this event.
        let state: GestureState
        /// The centroid of all touches in screen coordinates (`recognizer.location(in: nil)`).
        let location: CGPoint
        /// The number of fingers on screen when this event was recorded.
        let touches: Int
        /// The wall-clock time this event was recorded.
        let timestamp: Date
        /// When `true`, the event row animates to zero opacity before being removed from the list.
        var isExpiring = false
    }

    /// The view model that owns all mutable state for `LongPressGestureView`.
    ///
    /// Configuration properties (`minimumPressDuration`, `numberOfTouchesRequired`,
    /// `numberOfTapsRequired`) drive the gesture recognizer setup. The `gestureEvents`
    /// array feeds the event log. Calling ``addEvent(state:location:touches:)``
    /// appends a new event and schedules its automatic removal after 3 seconds.
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
        /// The chronological list of gesture events displayed in the event log.
        var gestureEvents: [GestureEvent] = []

        /// Records a new gesture event and schedules its removal after 3 seconds.
        ///
        /// The event is appended to ``gestureEvents`` immediately. After a 3-second delay,
        /// the event's `isExpiring` flag is set to `true` inside a 0.5-second ease-out
        /// animation. Once the animation completes, the event is removed from the array.
        ///
        /// - Parameters:
        ///   - state: The gesture phase (began, changed, or ended).
        ///   - location: The centroid of touches in screen coordinates.
        ///   - touches: The number of active fingers.
        func addEvent(state: GestureState, location: CGPoint, touches: Int) {
            currentState = state
            let event = GestureEvent(state: state, location: location, touches: touches, timestamp: .now)
            gestureEvents.append(event)
            let eventID = event.id

            Task {
                try? await Task.sleep(for: .seconds(3))
                guard let index = gestureEvents.firstIndex(where: { $0.id == eventID }) else { return }
                withAnimation(.easeOut(duration: 0.5)) {
                    gestureEvents[index].isExpiring = true
                } completion: { [self] in
                    gestureEvents.removeAll { $0.id == eventID }
                }
            }
        }
    }

    @State private var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ConfigurationSection(viewModel: viewModel)
            GesturePlayground(viewModel: viewModel)
            EventLog(viewModel: viewModel)
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
    /// (`onBegan`, `onChanged`, `onEnded`) each record an event via the view model.
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
                        viewModel.addEvent(
                            state: .began,
                            location: recognizer.location(in: nil),
                            touches: recognizer.numberOfTouches
                        )
                    }
                    .onChanged { recognizer in
                        viewModel.addEvent(
                            state: .changed,
                            location: recognizer.location(in: nil),
                            touches: recognizer.numberOfTouches
                        )
                    }
                    .onEnded { recognizer in
                        viewModel.addEvent(
                            state: .ended,
                            location: recognizer.location(in: nil),
                            touches: recognizer.numberOfTouches
                        )
                        viewModel.currentState = nil
                    }
                )
        }
    }

    // MARK: - Event Log

    /// A scrolling list of recent gesture events that automatically removes entries after 3 seconds.
    ///
    /// Each row displays:
    /// - A monospaced timestamp (`HH:mm:ss.SSS`).
    /// - The gesture state name, colored to match (yellow/green/red).
    /// - The touch centroid coordinates.
    /// - The number of active fingers.
    ///
    /// New events are appended at the bottom and the list auto-scrolls to keep the latest
    /// entry visible. After 3 seconds, each row fades out over 0.5 seconds and is removed
    /// from the backing array. When empty, a `ContentUnavailableView` placeholder is shown.
    private struct EventLog: View {

        var viewModel: ViewModel

        private static let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return formatter
        }()

        var body: some View {
            ScrollViewReader { proxy in
                List(viewModel.gestureEvents) { event in
                    HStack {
                        Text(Self.timeFormatter.string(from: event.timestamp))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        Text(event.state.localizedString)
                            .font(.callout.bold())
                            .foregroundStyle(event.state.color)
                        Spacer()
                        Text("(\(event.location.x, format: .number.precision(.fractionLength(1))), \(event.location.y, format: .number.precision(.fractionLength(1))))")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        Text("\(event.touches) finger(s)")
                            .font(.callout)
                    }
                    .id(event.id)
                    .opacity(event.isExpiring ? 0 : 1)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("\(event.state.localizedString) at \(Self.timeFormatter.string(from: event.timestamp)), \(event.touches) finger(s)"))
                }
                .listStyle(.plain)
                .overlay {
                    if viewModel.gestureEvents.isEmpty {
                        ContentUnavailableView("No Long Press Events",
                                               systemImage: "hand.tap",
                                               description: Text("Long press the rectangle above to log events."))
                    }
                }
                .onChange(of: viewModel.gestureEvents.last?.id) {
                    guard let lastID = viewModel.gestureEvents.last?.id else { return }
                    withAnimation {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }
            .frame(maxHeight: 250)
            .accessibilityLabel(String(localized: "Gesture event log"))
        }
    }
}

#Preview {
    NavigationStack {
        LongPressGestureView()
    }
}
