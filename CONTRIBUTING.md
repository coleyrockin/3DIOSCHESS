# Contributing to Chess3D

Thank you for your interest in contributing to Chess3D! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the code, not the person
- Welcome newcomers and help them get started

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
   ```bash
   git clone https://github.com/YOUR_USERNAME/3DIOSCHESS.git
   cd 3DIOSCHESS
   ```
3. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. **Set up your environment**
   - Xcode 15+
   - iOS 17+ simulator or device
   - XcodeGen (for regenerating projects): `brew install xcodegen`

## Development Workflow

### Before You Start

1. **Discuss major changes** — Open an issue first to discuss significant features or refactors
2. **Check existing issues** — Avoid duplicate work
3. **Keep commits atomic** — One feature/fix per commit

### Code Style

- **Follow Swift conventions** — Use standard Swift naming and style
- **Value types by default** — Prefer `struct` over `class` for data types
- **No force-unwraps in public paths** — Use `guard let` for safety
- **4-space indentation** with trailing commas on multi-line literals
- **No external dependencies** — Use only first-party Apple frameworks

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/descriptive-name
   ```

2. **Make your changes**
   - Keep changes focused and small
   - Write descriptive commit messages
   - Update documentation if needed

3. **Add tests for new features**
   - Place tests in `Tests/EngineTests.swift`
   - Ensure all tests pass: `Cmd+U` in Xcode
   - Aim for high coverage on engine logic

4. **Run the test suite**
   ```bash
   xcodebuild test -scheme Chess3DTests -destination "platform=iOS Simulator,name=iPhone 17 Pro"
   ```

5. **Build and verify**
   ```bash
   xcodebuild build -scheme Chess3D -destination "generic/platform=iOS Simulator"
   ```

### Commit Messages

Write clear, descriptive commit messages:

```
Brief summary (50 chars max)

More detailed explanation of what changed and why.
Mention any related issues or breaking changes.

Fixes #123
```

### Pull Request Process

1. **Push to your fork**
   ```bash
   git push origin feature/your-feature
   ```

2. **Create a Pull Request** on GitHub
   - Title: Clear, descriptive summary
   - Description: What changed and why
   - Reference related issues: "Fixes #123"

3. **Respond to feedback**
   - Make requested changes
   - Push updates to the same branch
   - Re-request review after changes

4. **Squash commits if needed**
   ```bash
   git rebase -i main
   ```

5. **Merge** once approved ✅

## What We're Looking For

### Good Contributions

✅ Bug fixes with test coverage
✅ Performance improvements with benchmarks
✅ Feature enhancements with documentation
✅ Test coverage improvements
✅ Documentation and README improvements
✅ Refactoring that improves maintainability

### Things to Avoid

❌ Breaking API changes without discussion
❌ Large PRs without prior discussion
❌ Code without tests
❌ External dependencies
❌ Platform-specific hacks

## Testing Guidelines

### Engine Tests

- Test move validation (legal/illegal moves)
- Test check and checkmate detection
- Test draw conditions
- Test special moves (castling, en passant, promotion)
- Verify AI doesn't crash on terminal positions

### UI Tests

- Visual regression testing in the Simulator
- Test on both iPhone and iPad layouts
- Verify touch input handling
- Check animation smoothness

### Example Test

```swift
func testCustomFeature() {
    var state = Rules.initialState()

    // Setup
    // ... arrange test state ...

    // Action
    let result = Rules.makeMove(move, in: &state)

    // Assert
    XCTAssertTrue(result)
    XCTAssertEqual(state.status, .ongoing)
}
```

## Common Tasks

### Adding a New Feature

1. Discuss in an issue first
2. Create feature branch: `feature/my-feature`
3. Implement with tests
4. Update README.md if needed
5. Submit PR with clear description

### Fixing a Bug

1. Create an issue describing the bug
2. Create bugfix branch: `fix/bug-description`
3. Add a test that reproduces the bug
4. Fix the bug (test should pass)
5. Submit PR with reference to the issue

### Improving Performance

1. Benchmark the current implementation
2. Implement optimization
3. Benchmark the new implementation
4. Document performance improvements in PR
5. Ensure no regression in other areas

## Documentation

- Update README.md for user-facing changes
- Update CLAUDE.md for architecture/developer info
- Add inline comments for complex logic
- Keep documentation in sync with code

## Questions?

- Check the [README.md](README.md) and [CLAUDE.md](CLAUDE.md)
- Review existing issues and discussions
- Ask in a new issue if you need help

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Chess3D! 🎉♟️
