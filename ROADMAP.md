# Roadmap

This document tracks planned improvements and future features for Chess3D.
Items are grouped by theme and roughly ordered by priority within each section.

---

## 🚀 Near-Term (Next Release)

### Gameplay
- [ ] **Pawn promotion UI** — Let the player choose promotion piece (queen/rook/bishop/knight) via an in-game picker instead of auto-promoting to queen
- [ ] **Adjudication offers** — Draw offer and accept/decline flow between players in hot-seat and online modes
- [ ] **Move timer** — Optional per-move clock (e.g., 5 s / 10 s blitz mode) with forfeit on timeout
- [ ] **Algebraic move log** — Scrollable list of moves in standard algebraic notation displayed in the HUD

### AI
- [ ] **Improved evaluation** — Piece-square tables (PST) for positional play; encourage central control, king safety, and pawn structure
- [ ] **Opening book** — Small built-in table of common openings to vary early-game play
- [ ] **Iterative deepening** — Time-bounded search that deepens until the clock runs out for smoother difficulty scaling

### UI / UX
- [ ] **Theme picker** — Allow players to switch between board colour schemes (classic wood, neon, marble)
- [ ] **Piece style options** — Alternative piece geometry (flat/2D style alongside the existing 3D set)
- [ ] **Accessibility** — VoiceOver support with readable square and piece descriptions; high-contrast board option

---

## 🛠️ Medium-Term

### Gameplay
- [ ] **PGN import / export** — Load and save games in standard Portable Game Notation
- [ ] **Analysis mode** — Step through a completed game move-by-move with engine evaluation per position
- [ ] **Puzzle mode** — Short tactical puzzles ("White to move — find the checkmate in 2")

### AI
- [ ] **Higher difficulty levels** — Depth-4+ search with time management; optional "grandmaster" mode
- [ ] **Endgame tablebase** — Lookup-based perfect play for K+Q vs K, K+R vs K, etc.

### Online / Social
- [ ] **Turn-based (async) matches** — Game Center turn-based API so players don't have to be online simultaneously
- [ ] **In-game chat** — Simple text or emoji reactions during online play
- [ ] **Match history** — Persist and review past online games

### Persistence & Sync
- [ ] **iCloud sync** — Back up saved games and preferences via CloudKit
- [ ] **Multiple save slots** — Save several games simultaneously and load any of them

---

## 🔭 Long-Term / Exploratory

### Platform Expansion
- [ ] **iPad split-screen** — Full side-by-side multitasking support
- [ ] **macOS (Catalyst / native)** — Native Mac app from the same codebase
- [ ] **Apple Watch companion** — Glance at game status and receive move notifications on wrist

### Visual & Audio
- [ ] **Full sound design** — Ambient music track, richer capture / check sound effects, voice-over announcements
- [ ] **Animated piece introductions** — Cinematic camera sweep at game start
- [ ] **ARKit board mode** — Place the board in your real-world space via augmented reality

### Engine
- [ ] **Neural network evaluation** — Replace hand-crafted eval with a small on-device NNUE-style model
- [ ] **Parallel search** — Multi-threaded alpha-beta using Swift concurrency (`async` task trees)

---

## ✅ Completed

See [CHANGELOG.md](CHANGELOG.md) for everything that has shipped.

---

*Want to contribute to any of these items? See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.*
