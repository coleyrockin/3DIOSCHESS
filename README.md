# Chess3D

A stunning 3D chess game for iOS with physically-based lighting, smooth animations, and intelligent AI.

![Swift](https://img.shields.io/badge/Swift-5.0+-orange?style=flat-square)
![iOS](https://img.shields.io/badge/iOS-17.0+-blue?style=flat-square)
![Xcode](https://img.shields.io/badge/Xcode-15+-lightgrey?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

## Screenshots

> *Run the app on an iOS 17+ Simulator (iPhone or iPad) to see it in action.*

| Home / Menu | 3D Board | Check Alert |
|:-----------:|:--------:|:-----------:|
| _(coming soon)_ | _(coming soon)_ | _(coming soon)_ |

## Features

- 🎮 **Three Game Modes**
  - Hot-seat: Two players on one device
  - Local AI: Play against an intelligent computer opponent
  - Online: Real-time multiplayer via Game Center

- 🎨 **Immersive 3D Experience**
  - Rendered with SceneKit and physically-based lighting
  - Smooth piece animations with particle effects
  - Camera idle motion for visual appeal
  - Board auto-rotates toward the active player with 60 fps orbit/zoom controls
  - Responsive touch controls with visual feedback

- ♟️ **Full Chess Rules**
  - All piece types with correct movement rules
  - Castling, en passant, pawn promotion
  - Check and checkmate detection
  - Draw conditions: stalemate, 50-move rule, insufficient material, threefold repetition
  - Move validation and legal move highlighting

- 🤖 **Intelligent AI**
  - Minimax algorithm with alpha-beta pruning
  - Material and mobility evaluation
  - Configurable search depth
  - Runs on background thread for responsive UI

- 💾 **Game Persistence**
  - Save and load games as JSON
  - Resume interrupted games
  - Full game history tracking

- 🎯 **Responsive UI**
  - Adaptive layouts for iPhone and iPad
  - Dark theme with futuristic neon accents
  - Glass panel design system
  - Haptic feedback and sound effects

## Getting Started

### Requirements

- **Xcode** 15 or later
- **iOS** 17.0 or later (simulator or device)
- **Swift** 5.0+
- No external dependencies

### Build & Run

1. **Clone the repository**
   ```bash
   git clone https://github.com/coleyrockin/3DIOSCHESS.git
   cd 3DIOSCHESS
   ```

2. **Open in Xcode**
   ```bash
   open Chess3D.xcodeproj
   ```

3. **Select a simulator**
   - Choose an iOS 17+ simulator (e.g., iPhone 17 Pro)
   - Or connect a physical iOS device

4. **Build and run**
   - Press `Cmd+R` or click the Run button
   - The app will launch on the selected device/simulator

### Run Tests

```bash
# Via Xcode
Select the Chess3DTests scheme and press Cmd+U

# Via command line
xcodebuild test -scheme Chess3DTests -destination "platform=iOS Simulator,name=iPhone 17 Pro"
```

All 37 tests pass, covering:
- Engine rules and move validation
- Check/checkmate/stalemate detection
- Castling and en passant
- Draw conditions
- AI move generation and evaluation

## Architecture

The project follows **MVVM** with a reactive state pipeline:

```
Engine (pure logic) → GameStore (ObservableObject) → SwiftUI views + SceneKit rendering
```

### Project Structure

```
Chess3D/
├── Engine/              # Pure game logic (no UI dependencies)
│   ├── Piece.swift      # Piece types and colors
│   ├── Move.swift       # Move representation with algebraic notation
│   ├── Board.swift      # 64-square flat array representation
│   ├── GameState.swift  # Full game state
│   ├── MoveGenerator.swift      # Pseudo-legal move generation
│   ├── LegalMoveFilter.swift    # Legal move validation
│   ├── CheckDetector.swift      # Attack detection
│   └── Rules.swift      # Public game API
│
├── AI/                  # Artificial intelligence
│   ├── ChessAI.swift    # Minimax with alpha-beta pruning
│   └── Evaluator.swift  # Position evaluation
│
├── Rendering/           # 3D graphics with SceneKit
│   ├── ChessScene.swift         # Root SCNScene management
│   ├── ChessSceneViewController.swift  # UIViewController wrapper
│   ├── PieceNodeFactory.swift   # 3D piece geometry
│   ├── BoardNodeFactory.swift   # 3D board geometry
│   ├── SelectionHighlighter.swift      # Move highlights
│   └── InputMapper.swift        # Touch-to-square mapping
│
├── App/                 # SwiftUI UI layer
│   ├── Chess3DApp.swift         # App entry point
│   ├── RootView.swift           # Adaptive layout (iPad/iPhone)
│   ├── GameContainerView.swift  # Board + HUD layout
│   ├── GameStore.swift          # State management
│   ├── OfflineMenuView.swift    # Offline game options
│   ├── OnlineMenuView.swift     # Online game options
│   └── DesignSystem.swift       # Colors, typography, styles
│
├── Online/              # Game Center integration
│   ├── OnlineSession.swift      # Authentication & matchmaking
│   ├── OnlineGameCoordinator.swift  # Match coordination
│   └── MatchMessenger.swift     # Move transmission
│
├── Persistence/         # Game save/load
│   └── SaveManager.swift        # JSON serialization
│
└── Tests/               # Unit tests
    └── EngineTests.swift        # Comprehensive engine tests
```

## Game Modes

### Hot-Seat
Play locally with another person on the same device. Perfect for passing the device back and forth between players.

### Local AI
Challenge the computer opponent. The AI searches 2 moves ahead by default:
```swift
// To adjust AI difficulty, edit GameStore.swift:
private let ai = ChessAI(maxDepth: 2)  // Increase for stronger play
```
Note: Each increase in depth multiplies thinking time by ~20x due to branching factor.

### Online (Game Center)
- Authenticate with your Apple ID
- Find opponents for real-time matches
- Move transmission via Game Center's `GKMatch`
- Full game state synchronization

## Key Classes

### Engine

| Class | Purpose |
|-------|---------|
| `GameState` | Complete game state: board, turn, castling rights, move history |
| `Board` | 64-element flat array for efficient piece storage |
| `Rules` | Public API for move validation and game updates |
| `MoveGenerator` | Generates all pseudo-legal moves |
| `LegalMoveFilter` | Filters moves that leave king in check |
| `CheckDetector` | Ray-casting based attack detection |

### Rendering

| Class | Purpose |
|-------|---------|
| `ChessScene` | SCNScene management, piece nodes, animations |
| `PieceNodeFactory` | Builds and caches 3D piece models |
| `SelectionHighlighter` | Overlay planes for selection/legal move display |
| `InputMapper` | Hit-tests SCNView to convert screen taps to board squares |

### State Management

| Class | Purpose |
|-------|---------|
| `GameStore` | Centralized state (board, turn, selected square, etc.) |
| `OnlineGameCoordinator` | Manages online match state and move transmission |

## Development Workflow

1. **Make Engine changes first** — Engine code has no UI dependencies and can be tested in isolation
2. **Run tests after changes** — `Cmd+U` with Chess3DTests scheme
3. **Handle status cascades** — Changing `GameStatus` requires updating exhaustive switches
4. **Test AI behavior** — Start a local AI game and verify the AI responds in ~1 second at depth 2
5. **Verify rendering** — Check visual changes in the iOS Simulator

## Common Tasks

### Increase AI Search Depth

Edit `GameStore.swift`:
```swift
private let ai = ChessAI(maxDepth: 3)  // Depth 3 is ~20x slower than depth 2
```

### Add a New Draw Condition

1. Add case to `GameStatus` in `Engine/GameState.swift`
2. Detect condition in `Rules.updateStatus()` in `Engine/Rules.swift`
3. Update exhaustive switches in:
   - `Evaluator.swift`
   - `ChessAI.swift`
   - `GameContainerView.swift`
   - `ChessScene.swift`
4. Add test case in `Tests/EngineTests.swift`

### Add a New Piece Type

1. Add case to `PieceType` in `Engine/Piece.swift`
2. Add 3D geometry in `PieceNodeFactory.buildPrototype(for:)` in `Rendering/PieceNodeFactory.swift`
3. Add move generation in `MoveGenerator` in `Engine/MoveGenerator.swift`
4. Add tests in `Tests/EngineTests.swift`

## Code Style

- **Value types by default**: Engine types are `struct`
- **Enum namespaces**: Stateless logic uses `enum` with `static` members
- **`@MainActor` for UI**: Only UI-touching types use this attribute
- **No force-unwrap on user input**: Use `guard let` for failable initializers
- **4-space indentation** with trailing commas on multi-line literals
- **No external dependencies**: Pure Swift and Apple frameworks only

## Testing

```bash
# Run all tests
xcodebuild test -scheme Chess3DTests -destination "platform=iOS Simulator,name=iPhone 17 Pro"

# Run specific test class
xcodebuild test -scheme Chess3DTests -destination "platform=iOS Simulator,name=iPhone 17 Pro" -only-testing Chess3DTests/EngineTests

# Run a specific test
xcodebuild test -scheme Chess3DTests -destination "platform=iOS Simulator,name=iPhone 17 Pro" -only-testing Chess3DTests/EngineTests/testScholarsMateCheckmate
```

### Test Coverage

- **EngineTests** (31 tests): Move validation, check/checkmate, castling, en passant, draws, promotion
- **AITests** (6 tests): Move legality, terminal position handling, evaluation

## Performance

- Board representation: O(1) piece lookup via 64-element array
- Move generation: ~200-300 moves per position on average
- AI search: ~1 second at depth 2, ~20 seconds at depth 3 on typical positions
- Rendering: Smooth 60 FPS with particle effects and camera animations

## Troubleshooting

### Tests fail with "test bundle executable couldn't be located"
Regenerate the Xcode project:
```bash
xcodegen generate
```

### AI takes too long to move
Reduce search depth in `GameStore.swift`:
```swift
private let ai = ChessAI(maxDepth: 2)  // Depth 1 for instant moves
```

### Online multiplayer not working
- Ensure Game Center is enabled in Xcode capabilities
- Use a real device with a valid Apple ID for testing
- Check network connectivity

## Roadmap

Planned features and improvements are tracked in [ROADMAP.md](ROADMAP.md).
Highlights include pawn-promotion UI, PGN export, an improved AI evaluator with
piece-square tables, iCloud sync, and an ARKit board mode.

## Contributing

Contributions are welcome! Please:
1. Create a feature branch from `main`
2. Add tests for new functionality
3. Ensure all tests pass
4. Submit a pull request with a clear description

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines and [ROADMAP.md](ROADMAP.md) for planned work.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Security

For security policy and reporting vulnerabilities, see [SECURITY.md](SECURITY.md).

## Author

Created with ❤️ for iOS chess enthusiasts.

---

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Overview, setup, architecture |
| [ROADMAP.md](ROADMAP.md) | Planned features and future improvements |
| [CHANGELOG.md](CHANGELOG.md) | Release history |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines |
| [SECURITY.md](SECURITY.md) | Security policy |
| [CLAUDE.md](CLAUDE.md) | Developer architecture reference |

**Ready to play?** Build and run the app, select a game mode, and enjoy!
