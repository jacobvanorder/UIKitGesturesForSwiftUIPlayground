# UIKitGesturesForSwiftUI Playground

A sample iOS app that demonstrates every gesture provided by the [UIKitGesturesForSwiftUI](https://github.com/jacobvanorder/UIKitGesturesForSwiftUI) library. Each gesture has its own interactive screen where you can adjust configuration, perform the gesture on a target rectangle, and observe real-time feedback.

Made by Jacob Van Order who you can find on Mastodon [here](https://mastodon.social/@jacobvo). Reach out if you have any feedback!

## Why This App Exists

SwiftUI's built-in gesture system has notable limitations. `DragGesture` only supports a single finger, there is no native multi-finger tap or swipe, and access to UIKit-level data such as velocity, touch count, and recognizer state is unavailable. [UIKitGesturesForSwiftUI](https://github.com/jacobvanorder/UIKitGesturesForSwiftUI) bridges that gap by wrapping UIKit's `UIGestureRecognizer` family in a declarative SwiftUI API. This playground app lets you explore each gesture hands-on.

## Requirements

| Requirement | Version |
|---|---|
| iOS | 18.0+ |
| Swift | 6.0 |
| Xcode | 16.0+ |

## Getting Started

1. Clone this repository.
2. Open `UIKitGesturesForSwiftUIPlayground.xcodeproj` in Xcode.
3. Xcode will automatically resolve the [UIKitGesturesForSwiftUI](https://github.com/jacobvanorder/UIKitGesturesForSwiftUI) Swift Package dependency.
4. Build and run on a simulator or device.

## Gesture Demos

The app opens to a navigation list. Tapping a row pushes a dedicated playground for that gesture.

### Pan Gesture

Demonstrates `MultiFingerPanGesture`. A draggable rectangle tracks multi-finger panning in real time.

- **Configuration**: Minimum and maximum number of touches (1--5).
- **Playground**: The rectangle follows your fingers and changes color to reflect the gesture state (began, changed, ended). On gesture end it remains at its new position.
- **Info Panel**: Displays the current state, touch location, and number of active fingers.

### Tap Gesture

Demonstrates `MultiFingerTapGesture`. A discrete gesture that fires once when the required taps and touches are met.

- **Configuration**: Number of taps required (1--5) and number of touches required (1--5).
- **Playground**: The rectangle flashes green when a tap is recognized.
- **Event Log**: A rolling list of recognized tap events showing timestamp, tap count, and finger count. Entries fade out after 3 seconds.

### Long Press Gesture

Demonstrates `MultiFingerLongPressGesture`. A continuous gesture that begins after a configurable hold duration.

- **Configuration**: Minimum press duration (0.25--3.0 s), touches required (1--5), and taps required (0--5).
- **Playground**: The rectangle changes color through the gesture lifecycle -- yellow on began, green on changed, red on ended, blue when idle.
- **Info Panel**: Displays the current state, touch location, and number of active fingers.

### Swipe Gesture

Demonstrates `MultiFingerSwipeGesture`. A discrete gesture that recognizes directional swipes.

- **Configuration**: Swipe direction (right, left, up, down) via a segmented picker, and touches required (1--5).
- **Playground**: The rectangle displays an arrow indicating the configured direction and flashes green on recognition.
- **Event Log**: A rolling list of recognized swipe events showing timestamp, direction, and finger count.

> **Note**: When the swipe direction is set to *right*, the system's interactive pop gesture (swipe-from-left-edge to go back) would normally intercept the swipe. The app conditionally hides the navigation back button in this case -- which also disables the edge-swipe gesture -- and provides a custom back button in the toolbar.

### Pinch Gesture

Demonstrates `MultiFingerPinchGesture`. A continuous two-finger gesture that reports scale and velocity.

- **Configuration**: Informational only -- the pinch gesture always requires exactly two fingers.
- **Playground**: The rectangle scales with the pinch and animates back to its original size on gesture end.
- **Info Panel**: Displays the current state, scale factor, and velocity.

### Rotation Gesture

Demonstrates `MultiFingerRotationGesture`. A continuous two-finger gesture that reports rotation angle and velocity.

- **Configuration**: Informational only -- the rotation gesture always requires exactly two fingers.
- **Playground**: The rectangle rotates with the gesture and animates back to 0 degrees on gesture end.
- **Info Panel**: Displays the current state, rotation (in degrees), and velocity (in degrees per second).

### Transform Gesture

Demonstrates `MultiFingerTransformGesture`. A custom continuous gesture that combines pan, pinch, and rotation into a single two-finger interaction using a custom `TransformGestureRecognizer`.

- **Configuration**: Informational only -- the transform gesture always requires exactly two fingers.
- **Playground**: The rectangle simultaneously translates, scales, and rotates. All three transforms animate back to identity on gesture end.
- **Info Panel**: Displays the current state, translation offset, scale factor, and rotation (in degrees).

## Architecture

Each gesture demo follows a consistent three-section layout:

```
+------------------------------+
|    Configuration Section     |  Steppers, pickers, or info label
+------------------------------+
|                              |
|     Gesture Playground       |  Interactive colored rectangle
|                              |
+------------------------------+
|   Info Panel / Event Log     |  Real-time values or rolling log
+------------------------------+
```

## License

This sample app is provided as a companion to [UIKitGesturesForSwiftUI](https://github.com/jacobvanorder/UIKitGesturesForSwiftUI). See the library repository for license details.
