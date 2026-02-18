//
//  SwipeGestureView.swift
//  UIKitGesturesForSwiftUIPlayground
//
//  Created by Jacob Van Order on 2/18/26.
//

import SwiftUI
import UIKitGesturesForSwiftUI

/// A playground view that demonstrates the `MultiFingerSwipeGesture` from UIKitGesturesForSwiftUI.
///
/// The view is divided into three vertical sections:
/// 1. **Configuration** — a segmented picker to choose the swipe direction (right, left, up, down)
///    and a stepper to adjust the number of touches required for recognition.
/// 2. **Gesture Playground** — a blue rectangle that serves as the swipe target. The rectangle
///    briefly flashes green when a swipe is recognized.
/// 3. **Event Log** — a scrolling list of recognized swipe events. Each entry shows a timestamp,
///    the swipe direction, and finger count. Entries automatically fade out and are removed
///    after 3 seconds.
struct SwipeGestureView: View {

    /// The four cardinal swipe directions available for configuration.
    ///
    /// Each case wraps the corresponding `UISwipeGestureRecognizer.Direction` value and
    /// provides a localized display name and SF Symbol for the UI.
    enum SwipeDirection: String, CaseIterable, Identifiable {
        case right
        case left
        case up
        case down

        var id: Self { self }

        /// The underlying `UISwipeGestureRecognizer.Direction` value.
        var uiDirection: UISwipeGestureRecognizer.Direction {
            switch self {
            case .right: .right
            case .left: .left
            case .up: .up
            case .down: .down
            }
        }

        /// A localized, human-readable label for this direction.
        var localizedString: String {
            switch self {
            case .right: String(localized: "Right")
            case .left: String(localized: "Left")
            case .up: String(localized: "Up")
            case .down: String(localized: "Down")
            }
        }

        /// An SF Symbol name representing an arrow in this direction.
        var systemImage: String {
            switch self {
            case .right: "arrow.right"
            case .left: "arrow.left"
            case .up: "arrow.up"
            case .down: "arrow.down"
            }
        }
    }

    /// A single recorded swipe event, displayed in the event log.
    ///
    /// Each event captures the direction of the swipe, the number of fingers used,
    /// and the wall-clock time it occurred. The `isExpiring` flag drives a fade-out
    /// animation before the event is removed from the list.
    struct SwipeEvent: Identifiable {
        let id = UUID()
        /// The direction of the recognized swipe.
        let direction: SwipeDirection
        /// The number of fingers on screen when the swipe was recognized.
        let touches: Int
        /// The wall-clock time this event was recorded.
        let timestamp: Date
        /// When `true`, the event row animates to zero opacity before being removed from the list.
        var isExpiring = false
    }

    /// The view model that owns all mutable state for `SwipeGestureView`.
    ///
    /// Configuration properties (`direction`, `numberOfTouchesRequired`) drive the gesture
    /// recognizer setup. The `swipeEvents` array feeds the event log.
    /// Calling ``addSwipeEvent(direction:touches:)`` appends a new event and schedules
    /// its automatic removal after 3 seconds.
    @Observable
    class ViewModel {
        /// The direction the swipe must travel to be recognized.
        var direction: SwipeDirection = .right
        /// The number of fingers that must be on screen for the swipe to be recognized (1–5).
        var numberOfTouchesRequired: Int = 1
        /// Whether the rectangle is showing a recognition flash.
        /// Briefly set to `true` when a swipe is recognized, then reset after a short delay.
        var isShowingRecognition = false
        /// The chronological list of swipe events displayed in the event log.
        var swipeEvents: [SwipeEvent] = []

        /// Records a new swipe event and schedules its removal after 3 seconds.
        ///
        /// The event is appended to ``swipeEvents`` immediately. The rectangle flashes
        /// green for 0.3 seconds to provide visual feedback. After a 3-second delay,
        /// the event's `isExpiring` flag is set to `true` inside a 0.5-second ease-out
        /// animation. Once the animation completes, the event is removed from the array.
        ///
        /// - Parameters:
        ///   - direction: The direction of the recognized swipe.
        ///   - touches: The number of fingers that performed the swipe.
        func addSwipeEvent(direction: SwipeDirection, touches: Int) {
            let event = SwipeEvent(direction: direction, touches: touches, timestamp: .now)
            swipeEvents.append(event)
            let eventID = event.id

            isShowingRecognition = true
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                isShowingRecognition = false
            }

            Task {
                try? await Task.sleep(for: .seconds(3))
                guard let index = swipeEvents.firstIndex(where: { $0.id == eventID }) else { return }
                withAnimation(.easeOut(duration: 0.5)) {
                    swipeEvents[index].isExpiring = true
                } completion: { [self] in
                    swipeEvents.removeAll { $0.id == eventID }
                }
            }
        }
    }

    @State private var viewModel = ViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ConfigurationSection(viewModel: viewModel)
            GesturePlayground(viewModel: viewModel)
            EventLog(viewModel: viewModel)
        }
        .navigationTitle(String(localized: "Swipe Gesture"))
        // When the configured swipe direction is `.right`, the system's interactive
        // pop gesture (swipe-from-left-edge to go back) intercepts the swipe before
        // the `MultiFingerSwipeGesture` can recognize it. Hiding the back button via
        // `navigationBarBackButtonHidden` also disables that edge-swipe gesture,
        // allowing right-swipes to reach the playground's gesture recognizer.
        // A custom toolbar button restores the back navigation affordance.
        .navigationBarBackButtonHidden(viewModel.direction == .right)
        .toolbar {
            if viewModel.direction == .right {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.backward")
                            Text(String(localized: "Back"))
                        }
                    }
                    .accessibilityLabel(String(localized: "Back"))
                }
            }
        }
    }

    // MARK: - Configuration Section

    /// Displays controls for adjusting the swipe gesture's configuration.
    ///
    /// - **Direction**: A segmented picker with arrow icons for right, left, up, and down.
    /// - **Touches Required**: 1–5 simultaneous fingers via a stepper.
    private struct ConfigurationSection: View {

        @Bindable var viewModel: ViewModel

        var body: some View {
            Form {
                Section {
                    Picker(String(localized: "Direction"), selection: $viewModel.direction) {
                        ForEach(SwipeDirection.allCases) { direction in
                            Image(systemName: direction.systemImage)
                                .accessibilityLabel(direction.localizedString)
                                .tag(direction)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityHint(String(localized: "Selects the swipe direction required to recognize the gesture."))

                    Stepper("Touches Required: \(viewModel.numberOfTouchesRequired)",
                            value: $viewModel.numberOfTouchesRequired,
                            in: 1...5)
                    .accessibilityValue("\(viewModel.numberOfTouchesRequired)")
                    .accessibilityHint(String(localized: "Adjusts the number of fingers required to recognize the swipe."))
                }
            }
            .formStyle(.grouped)
            .frame(height: 160)
        }
    }

    // MARK: - Gesture Playground

    /// The interactive area where the user performs swipe gestures.
    ///
    /// A 150×150 rounded rectangle is centered in the available space. It displays a
    /// directional arrow overlay indicating the configured swipe direction. The rectangle
    /// briefly flashes green when a swipe is successfully recognized, providing immediate
    /// visual feedback.
    ///
    /// A `MultiFingerSwipeGesture` is attached to the entire area. Its `onEnded` callback
    /// records the event via the view model.
    private struct GesturePlayground: View {

        var viewModel: ViewModel

        /// A human-readable summary of the current gesture configuration for VoiceOver.
        private var configurationSummary: String {
            String(localized: "Swipe target. Swipe \(viewModel.direction.localizedString.lowercased()) with \(viewModel.numberOfTouchesRequired) finger(s).")
        }

        var body: some View {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(viewModel.isShowingRecognition ? .green : .blue)
                        .frame(width: 150, height: 150)
                        .overlay {
                            Image(systemName: viewModel.direction.systemImage)
                                .font(.largeTitle)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .animation(.easeOut(duration: 0.15), value: viewModel.isShowingRecognition)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.direction)
                        .accessibilityLabel(String(localized: "Swipe target"))
                        .accessibilityValue(viewModel.direction.localizedString)
                        .accessibilityHint(configurationSummary)
                }
                .contentShape(Rectangle())
                .gesture(
                    MultiFingerSwipeGesture(
                        direction: viewModel.direction.uiDirection,
                        numberOfTouchesRequired: viewModel.numberOfTouchesRequired
                    )
                    .onEnded { recognizer in
                        viewModel.addSwipeEvent(
                            direction: viewModel.direction,
                            touches: recognizer.numberOfTouches
                        )
                    }
                )
        }
    }

    // MARK: - Event Log

    /// A scrolling list of recent swipe events that automatically removes entries after 3 seconds.
    ///
    /// Each row displays:
    /// - A monospaced timestamp (`HH:mm:ss.SSS`).
    /// - A directional arrow icon matching the swipe direction.
    /// - The localized direction name.
    /// - The number of fingers used.
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
                List(viewModel.swipeEvents) { event in
                    HStack {
                        Text(Self.timeFormatter.string(from: event.timestamp))
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                        Image(systemName: event.direction.systemImage)
                            .foregroundStyle(.green)
                        Text(event.direction.localizedString)
                            .font(.callout.bold())
                            .foregroundStyle(.green)
                        Spacer()
                        Text("\(event.touches) finger(s)")
                            .font(.callout)
                    }
                    .id(event.id)
                    .opacity(event.isExpiring ? 0 : 1)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("Swiped \(event.direction.localizedString.lowercased()) with \(event.touches) finger(s) at \(Self.timeFormatter.string(from: event.timestamp))"))
                }
                .listStyle(.plain)
                .overlay {
                    if viewModel.swipeEvents.isEmpty {
                        ContentUnavailableView(String(localized: "No Swipe Events"),
                                               systemImage: "hand.draw",
                                               description: Text("Swipe on the rectangle above to log events."))
                    }
                }
                .onChange(of: viewModel.swipeEvents.last?.id) {
                    guard let lastID = viewModel.swipeEvents.last?.id else { return }
                    withAnimation {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }
            .frame(maxHeight: 250)
            .accessibilityLabel(String(localized: "Swipe event log"))
        }
    }
}

#Preview {
    NavigationStack {
        SwipeGestureView()
    }
}
