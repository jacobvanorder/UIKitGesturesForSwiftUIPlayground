# Project: UIKitGesturesForSwiftUIPlayground

## Quick Reference
- **Platform**: iOS 18+
- **Language**: Swift 6.0
- **UI Framework**: SwiftUI, UIKit
- **Minimum Deployment**: iOS 18.0
- **Package Manager**: Swift Package Manager

## 🔍 Environment Adaptation

This project supports two Claude development environments:
- **Xcode 26.3+ Claude Agent SDK** - Uses Xcode built-in MCP tools
- **Pure Claude Code** - Uses command line Claude Code

### Environment Detection

Judge the current environment by checking the `CLAUDE_CONFIG_DIR` environment variable:

- ✅ **Contains `Xcode/CodingAssistant`** → Use configuration from [CLAUDE-XCODE.md](CLAUDE-XCODE.md)
  - Example: `~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig`
- ❌ **Does not contain or is another path** → Use configuration from [CLAUDE-PURE.md](CLAUDE-PURE.md)
  - Example: `~/.config/claude` or other standard configuration paths

## Coding Standards

### Swift Style
- Use Swift 6 strict concurrency
- Prefer `@Observable` over `ObservableObject`
- Use `async/await` for all async operations
- Follow Apple's Swift API Design Guidelines
- Use `guard` for early exits
- Prefer value types (structs) over reference types (classes)

### SwiftUI Patterns
- Extract views when they exceed 100 lines
- Use `@State` for local view state only
- Use `@Environment` for dependency injection
- Prefer `NavigationStack` over deprecated `NavigationView`
- Use `@Bindable` for bindings to @Observable objects


### Error Handling
```swift
// Always use typed errors
enum AppError: LocalizedError {
    case networkError(underlying: Error)
    case validationError(message: String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error): return error.localizedDescription
        case .validationError(let msg): return msg
        }
    }
}
```

## Testing Requirements
- Unit tests for all ViewModels
- UI tests for critical user flows
- Use Swift Testing framework (`@Test`, `#expect`)
- Minimum 80% code coverage for business logic

## DO NOT
- Write UITests during scaffolding phase
- Use deprecated APIs (UIKit when SwiftUI suffices)
- Create massive monolithic views
- Use force unwrapping (`!`) without justification
- Ignore Swift 6 concurrency warnings

## Planning Workflow
When starting new features:
1. Use `ultrathink` for architectural decisions
2. Use Plan Mode (`Shift+Tab`) for implementation strategy
3. Implement incrementally with tests
