# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-02-28

### Added
- Initial release of Chess3D
- Full chess game implementation with all standard rules
  - Piece movement (King, Queen, Rook, Bishop, Knight, Pawn)
  - Special moves (Castling, En Passant, Promotion)
  - Check and checkmate detection
  - Draw conditions (Stalemate, 50-move rule, Insufficient material, Threefold repetition)
- Three game modes
  - Hot-seat: Two players on one device
  - Local AI: Play against computer opponent with minimax algorithm
  - Online: Real-time multiplayer via Apple Game Center
- 3D rendering with SceneKit
  - Physically-based lighting
  - Piece animations with particle effects
  - Camera idle motion and smooth interactions
  - Touch-based board input
- Game persistence
  - Save and load games as JSON
  - Full game history tracking
- Comprehensive test suite (37 tests)
  - Engine rules validation
  - AI move generation and evaluation
  - Check/checkmate/stalemate detection
  - Special move handling
  - Draw condition detection
- Professional UI design
  - Adaptive layouts for iPhone and iPad
  - Dark theme with futuristic neon accents
  - Glass panel design system
  - Haptic feedback and sound effects
- Documentation
  - Comprehensive README
  - Architecture guide (CLAUDE.md)
  - Security policy (SECURITY.md)
  - Contributing guidelines
  - MIT License

### Technical Details
- Built with Swift 5.0+, SwiftUI, and SceneKit
- Requires iOS 17+
- No external dependencies
- Board representation: 64-element flat array for O(1) lookups
- AI search depth: 2 (configurable, depth 3 available for stronger play)
- Clean MVVM architecture with reactive state management

---

## Guidelines for Future Versions

### Adding Features
- Update version number in preparation
- Add entry to Unreleased section
- Move to version section when released

### Breaking Changes
- Clearly mark as breaking in changelog
- Consider API deprecation period first

### Security Fixes
- Use `[SECURITY]` prefix
- Consider emergency release if critical

### Dates
- Use YYYY-MM-DD format
- Finalize dates only at release time

---

For detailed development information, see [CONTRIBUTING.md](CONTRIBUTING.md).
