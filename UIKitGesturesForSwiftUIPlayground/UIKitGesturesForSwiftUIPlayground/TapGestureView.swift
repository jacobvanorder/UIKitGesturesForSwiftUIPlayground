//
//  TapGestureView.swift
//  UIKitGesturesForSwiftUIPlayground
//
//  Created by Jacob Van Order on 2/18/26.
//

import SwiftUI
import UIKitGesturesForSwiftUI

/// A playground view that demonstrates the `MultiFingerTapGesture` from UIKitGesturesForSwiftUI.
///
/// The view is divided into three vertical sections:
/// 1. **Configuration** — steppers to adjust the number of taps and touches required
///    for the gesture to be recognized.
/// 2. **Gesture Playground** — a blue rectangle that responds to tap gestures.
///    Tapping with the configured number of fingers and taps logs an event.
/// 3. **Event Log** — a scrolling list of recognized tap events. Each entry shows a
///    timestamp, tap count, and finger count. Entries automatically fade out and are
///    removed after 3 seconds.
struct TapGestureView: View {

    /// A single recorded tap event, displayed in the event log.
    ///
    /// Each event captures the number of touches and taps at recognition time,
    /// along with the wall-clock timestamp. The `isExpiring` flag drives a fade-out
    /// animation before the event is removed from the list.
    struct TapEvent: Identifiable {
        let id = UUID()
        /// The number of fingers on screen when the tap was recognized.
        let touches: Int
        /// The number of taps that were recognized (matches the configured requirement).
        let taps: Int
        /// The wall-clock time this event was recorded.
        let timestamp: Date
        /// When `true`, the event row animates to zero opacity before being removed from the list.
        var isExpiring = false
    }

    /// The view model that owns all mutable state for `TapGestureView`.
    ///
    /// Configuration properties (`numberOfTouchesRequired`, `numberOfTapsRequired`) drive
    /// the gesture recognizer setup. The `tapEvents` array feeds the event log.
    /// Calling ``addTapEvent(touches:taps:)`` appends a new event and schedules its
    /// automatic removal after 3 seconds.
    @Observable
    class ViewModel {
        /// The number of fingers that must touch the screen simultaneously for recognition (1–5).
        var numberOfTouchesRequired: Int = 1
        /// The number of consecutive taps required for the gesture to be recognized (1–5).
        var numberOfTapsRequired: Int = 1
        /// The chronological list of tap events displayed in the event log.
        var tapEvents: [TapEvent] = []

        /// Records a new tap event and schedules its removal after 3 seconds.
        ///
        /// The event is appended to ``tapEvents`` immediately. After a 3-second delay,
        /// the event's `isExpiring` flag is set to `true` inside a 0.5-second ease-out
        /// animation. Once the animation completes, the event is removed from the array.
        ///
        /// - Parameters:
        ///   - touches: The number of fingers that performed the tap.
        ///   - taps: The number of taps that were recognized.
        func addTapEvent(touches: Int, taps: Int) {
            let event = TapEvent(touches: touches, taps: taps, timestamp: .now)
            tapEvents.append(event)
            let eventID = event.id

            Task {
                try? await Task.sleep(for: .seconds(3))
                guard let index = tapEvents.firstIndex(where: { $0.id == eventID }) else { return }
                withAnimation(.easeOut(duration: 0.5)) {
                    tapEvents[index].isExpiring = true
                } completion: { [self] in
                    tapEvents.removeAll { $0.id == eventID }
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
        .navigationTitle(String(localized: "Tap Gesture"))
    }

    // MARK: - Configuration Section

    /// Displays steppers for adjusting the tap gesture's configuration.
    ///
    /// - **Taps Required**: 1–5 consecutive taps.
    /// - **Touches Required**: 1–5 simultaneous fingers.
    private struct ConfigurationSection: View {

        @Bindable var viewModel: ViewModel

        var body: some View {
            Form {
                Section {
                    Stepper("Taps Required: \(viewModel.numberOfTapsRequired)",
                            value: $viewModel.numberOfTapsRequired,
                            in: 1...5)
                    .accessibilityValue("\(viewModel.numberOfTapsRequired)")
                    .accessibilityHint(String(localized: "Adjusts the number of consecutive taps required to recognize the gesture."))

                    Stepper("Touches Required: \(viewModel.numberOfTouchesRequired)",
                            value: $viewModel.numberOfTouchesRequired,
                            in: 1...5)
                    .accessibilityValue("\(viewModel.numberOfTouchesRequired)")
                    .accessibilityHint(String(localized: "Adjusts the number of fingers required to recognize the gesture."))
                }
            }
            .formStyle(.grouped)
            .frame(height: 160)
        }
    }

    // MARK: - Gesture Playground

    /// The interactive area where the user performs tap gestures.
    ///
    /// A 150×150 blue rounded rectangle is centered in the available space. A
    /// `MultiFingerTapGesture` is attached to the entire area. When the gesture is
    /// recognized (the user taps with the configured number of fingers and taps),
    /// a new event is recorded via the view model.
    private struct GesturePlayground: View {

        var viewModel: ViewModel

        /// A human-readable summary of the current gesture configuration for VoiceOver.
        private var configurationSummary: String {
            String(localized: "Tap target. Requires \(viewModel.numberOfTapsRequired) tap(s) with \(viewModel.numberOfTouchesRequired) finger(s).")
        }

        var body: some View {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.blue)
                        .frame(width: 150, height: 150)
                        .accessibilityLabel(String(localized: "Tap target"))
                        .accessibilityHint(configurationSummary)
                }
                .contentShape(Rectangle())
                .gesture(
                    MultiFingerTapGesture(
                        numberOfTapsRequired: viewModel.numberOfTapsRequired,
                        numberOfTouchesRequired: viewModel.numberOfTouchesRequired
                    )
                    .onEnded { recognizer in
                        viewModel.addTapEvent(
                            touches: recognizer.numberOfTouches,
                            taps: recognizer.numberOfTapsRequired
                        )
                    }
                )
        }
    }

    // MARK: - Event Log

    /// A scrolling list of recent tap events that automatically removes entries after 3 seconds.
    ///
    /// Each row displays:
    /// - A monospaced timestamp (`HH:mm:ss.SSS`).
    /// - The number of taps and fingers that triggered the event.
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
                List(viewModel.tapEvents) { event in
                    HStack {
                        Text(Self.timeFormatter.string(from: event.timestamp))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(event.taps) tap(s), \(event.touches) finger(s)")
                            .font(.callout)
                    }
                    .id(event.id)
                    .opacity(event.isExpiring ? 0 : 1)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("\(event.taps) tap(s) with \(event.touches) finger(s) at \(Self.timeFormatter.string(from: event.timestamp))"))
                }
                .listStyle(.plain)
                .overlay {
                    if viewModel.tapEvents.isEmpty {
                        ContentUnavailableView("No Tap Events",
                                               systemImage: "hand.tap",
                                               description: Text("Tap the rectangle above to log events."))
                    }
                }
                .onChange(of: viewModel.tapEvents.last?.id) {
                    guard let lastID = viewModel.tapEvents.last?.id else { return }
                    withAnimation {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }
            .frame(maxHeight: 250)
            .accessibilityLabel(String(localized: "Tap event log"))
        }
    }
}

#Preview {
    NavigationStack {
        TapGestureView()
    }
}
