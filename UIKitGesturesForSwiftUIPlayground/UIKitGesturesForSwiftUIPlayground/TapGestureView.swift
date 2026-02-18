//
//  TapGestureView.swift
//  UIKitGesturesForSwiftUIPlayground
//
//  Created by Jacob Van Order on 2/18/26.
//

import SwiftUI
import UIKitGesturesForSwiftUI

struct TapGestureView: View {

    struct TapEvent: Identifiable {
        let id = UUID()
        let touches: Int
        let taps: Int
        let timestamp: Date
        var isExpiring = false
    }

    @Observable
    class ViewModel {
        var numberOfTouchesRequired: Int = 1
        var numberOfTapsRequired: Int = 1
        var tapEvents: [TapEvent] = []

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
        .navigationTitle("Tap Gesture")
    }

    private struct ConfigurationSection: View {

        @Bindable var viewModel: ViewModel

        var body: some View {
            Form {
                Section {
                    Stepper("Taps Required: \(viewModel.numberOfTapsRequired)",
                            value: $viewModel.numberOfTapsRequired,
                            in: 1...5)
                    Stepper("Touches Required: \(viewModel.numberOfTouchesRequired)",
                            value: $viewModel.numberOfTouchesRequired,
                            in: 1...5)
                }
            }
            .formStyle(.grouped)
            .frame(height: 160)
        }
    }

    private struct GesturePlayground: View {

        var viewModel: ViewModel

        var body: some View {
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.blue)
                        .frame(width: 150, height: 150)
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
        }
    }
}

#Preview {
    NavigationStack {
        TapGestureView()
    }
}
