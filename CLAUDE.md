# Chess3D

A 3D chess game for iOS built with Swift, SwiftUI, and SceneKit.

## Project Overview

Chess3D renders a fully-playable chess board in 3D with physically-based lighting, particle effects,
and camera animations. It supports hot-seat (two players on one device), local AI (minimax with
alpha-beta pruning), and online multiplayer via Game Center.

## Build Instructions

**Requirements:** Xcode 15+, iOS 17+ simulator or device, no external dependencies.

1. Open `Chess3D.xcodeproj` in Xcode
2. Select the **Chess3D** scheme and an iOS 17+ simulator
3. Press `Cmd+R` to build and run

To regenerate the project file from `project.yml` (requires [XcodeGen](https://github.com/yonaskolb/XcodeGen)):
```
xcodegen generate
```

**Run tests:** Select the **Chess3DTests** scheme and press `Cmd+U`.

## Architecture

The project follows MVVM with a reactive state pipeline:

```
Engine (pure logic) → GameStore (ObservableObject) → SwiftUI views + SceneKit rendering
```

| Group       | Responsibility |
|-------------|----------------|
| **Engine**  | Board, moves, rules, check/checkmate detection — pure Swift, no UI |
| **AI**      | Minimax search with alpha-beta pruning and material/mobility evaluation |
| **Rendering** | SceneKit 3D scene, piece models, lights, camera, selection highlights |
| **App**     | SwiftUI views, `GameStore` state management, design system |
| **Online**  | GameKit/Game Center matchmaking and real-time move transport |
| **Persistence** | JSON save/load of full game state |

## Module Breakdown

### Engine

- `Piece.swift` — `PieceColor`, `PieceType`, `Piece` value types
- `Move.swift` — `Square` (with algebraic init/output) and `Move` value types
- `Board.swift` — 64-element flat array; `allPieces()`, `pieces(for:)`, `movePiece(from:to:)`
- `GameState.swift` — Full state: board, turn, castling rights, en-passant target, clocks, status, position history
- `MoveGenerator.swift` — Pseudo-legal move generation for all piece types including castling
- `LegalMoveFilter.swift` — Filters pseudo-legal moves: simulate each move, verify king not in check
- `CheckDetector.swift` — Attack detection via ray-casting; `isKingInCheck`, `isSquareAttacked`
- `Rules.swift` — Public API: `makeMove`, `applyUnchecked`, `updateStatus`; enforces all draw conditions

### AI

- `Evaluator.swift` — Static evaluation: material balance + pseudo-legal mobility count
- `ChessAI.swift` — Minimax with alpha-beta pruning (default depth 2); runs on background thread

### Rendering

- `ChessScene.swift` — Root `SCNScene`; manages piece nodes, lighting, camera, check/checkmate effects
- `ChessSceneViewController.swift` — `UIViewController` wrapping `SCNView`; routes taps and hover gestures
- `PieceNodeFactory.swift` — Builds and caches prototype `SCNNode` trees per piece type/colour
- `BoardNodeFactory.swift` — Static board mesh, border frame, and edge glow
- `SelectionHighlighter.swift` — Overlay planes for selected, legal, and hovered squares
- `InputMapper.swift` — Hit-tests `SCNView` to map screen points to chess squares

### App

- `Chess3DApp.swift` — `@main` entry point
- `RootView.swift` — Adaptive layout: iPad split-view / iPhone stack; owns `GameStore`
- `GameContainerView.swift` — Board container + `GameHUDView`; bridges SwiftUI ↔ UIKit via `ChessSceneContainer`
- `GameStore.swift` — `@MainActor ObservableObject`; owns game state, AI scheduling, undo, resign, online coordination
- `DesignSystem.swift` — Colours, typography, glass-panel modifier, neon button style

### Online

- `OnlineSession.swift` — GameKit authentication and `GKMatch` lifecycle
- `OnlineGameCoordinator.swift` — Colour assignment; forwards remote moves to `GameStore`
- `MatchMessenger.swift` — JSON encode/decode of `Move` over the GKMatch wire

### Persistence

- `SaveManager.swift` — JSON encode/decode of `SavedGame` (state + history + mode) to Documents

## Game Status Values

`GameStatus` covers all terminal and non-terminal states:

| Case | Meaning |
|------|---------|
| `.ongoing` | Game in progress, no threats |
| `.check` | Current player's king is in check |
| `.checkmate` | Current player has no legal moves and is in check |
| `.stalemate` | Current player has no legal moves and is NOT in check (draw) |
| `.fiftyMoveRule` | 100 half-moves without pawn move or capture (draw) |
| `.insufficientMaterial` | Neither side can force checkmate (draw) |
| `.threefoldRepetition` | Same position occurred 3 times (draw) |
| `.resigned` | Current player resigned; `winner` is set to opponent |

When adding a new status, update the exhaustive switches in:
`Evaluator.swift`, `ChessAI.swift`, `GameContainerView.swift`, `ChessScene.swift`

## Code Style

- **Value types by default**: engine types (`Board`, `GameState`, `Move`, `Square`) are `struct`
- **Enum namespaces for stateless logic**: `Rules`, `MoveGenerator`, `CheckDetector`, `Evaluator`, `PieceNodeFactory`, `BoardNodeFactory` are `enum` with only `static` members
- **`@MainActor` for UI-touching types**: `GameStore` and `OnlineGameCoordinator`
- **Combine for reactive state**: `GameStore` publishes `@Published` properties consumed via `@ObservedObject`
- **No external dependencies**: all functionality uses first-party Apple frameworks
- **No force-unwrap on user-controlled paths**: `Square(file:rank:)` is failable; use `guard let` or `!` only on compile-time-known valid indices (e.g., board corners in castling logic)
- **4-space indentation**, trailing commas on multi-line array literals, `guard` for early exits

## Development Workflow

1. **Engine changes first**: `Engine/` has no UIKit/SceneKit imports and can be tested in isolation
2. **Run tests after any engine change**: `Cmd+U` with the `Chess3DTests` scheme
3. **Status changes cascade**: after touching `GameStatus`, fix all exhaustive switches (compiler-enforced)
4. **AI smoke test**: start a `localAI` game and confirm the AI responds within ~1 second at depth 2
5. **Rendering changes**: verify in the iOS Simulator; use Xcode's Metal HUD to watch GPU load

## Common Tasks

### Increasing AI search depth
In `GameStore.swift`, change `ChessAI(maxDepth: 2)` to a higher value.
Note: depth 3 roughly multiplies think-time by 20× due to branching factor.

### Adding a new draw condition
1. Add a case to `GameStatus` in `Engine/GameState.swift`
2. Detect the condition in `Rules.updateStatus()` in `Engine/Rules.swift`
3. Fix all exhaustive switch warnings (compiler will flag them)
4. Add a test in `Tests/EngineTests.swift`

### Adding a new piece type or visual style
1. Add the case to `PieceType` in `Engine/Piece.swift`
2. Add geometry in `PieceNodeFactory.buildPrototype(for:)` in `Rendering/PieceNodeFactory.swift`
3. Add move generation in `MoveGenerator` in `Engine/MoveGenerator.swift`

## Testing

Tests live in `Tests/` and use **XCTest** via `@testable import Chess3D`.

Test categories:
- **EngineTests**: rules correctness — check, checkmate, stalemate, castling, en passant, promotion, draw conditions, resign
- **AITests**: AI produces valid legal moves; handles terminal positions correctly
